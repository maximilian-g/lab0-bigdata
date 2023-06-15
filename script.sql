-- Useful commands:
SHOW DATABASES;

SELECT cluster, shard_num, host_name, host_address, port, is_local
FROM system.clusters;

SHOW TABLES FROM mgolovach_370819;

SHOW TABLES FROM mgolovach_370819;

select * FROM mgolovach_370819.transactions;

select * FROM mgolovach_370819.distr_transactions;
select count(*) FROM mgolovach_370819.distr_transactions;

-- Creating transaction table, partition by yyyymm part of datetime:

CREATE TABLE mgolovach_370819.transactions
    ON CLUSTER kube_clickhouse_cluster
(
    user_id_out Int64,
    user_id_in  Int64,
    important   Bool,
    amount      Float64,
    datetime    DateTime
)
    ENGINE = MergeTree()
        PARTITION BY toYYYYMM(datetime)
        ORDER BY (user_id_out, user_id_in);


-- Creating distributed table, sharding key - yyyymm part of datetime,
-- 12 shards total, because transactions contains only 2018 year data, only 12 month:

CREATE TABLE mgolovach_370819.distr_transactions
    ON CLUSTER kube_clickhouse_cluster AS mgolovach_370819.transactions
ENGINE = Distributed(
    kube_clickhouse_cluster,
    mgolovach_370819,
    transactions,
    intHash32(toYYYYMM(datetime))
    );

-- command to insert data:
-- cat shared-data/clickhouse_data/transactions_12M.parquet | clickhouse-client --user=mgolovach_370819 --host=clickhouse-5.clickhouse.clickhouse --password=0Xtr579L8I --query="INSERT INTO mgolovach_370819.distr_transactions FORMAT Parquet"

-- Users saldo for the current moment.
CREATE MATERIALIZED VIEW mgolovach_370819.saldo_for_each_user ON CLUSTER kube_clickhouse_cluster
            ENGINE = AggregatingMergeTree
                ORDER BY (user_id, saldo) POPULATE
AS
select out.user_id_out as user_id, (out.amount - in_table.amount) as saldo
from (select out.user_id_out,
             count(out.user_id_out) as incoming,
             sum(out.amount)        as amount
--       from mgolovach_370819.transactions out
      from mgolovach_370819.distr_transactions out
      group by out.user_id_out) out inner join
     (select in_table.user_id_in,
             count(in_table.user_id_in) as outcoming,
             sum(in_table.amount)       as amount
--       from mgolovach_370819.transactions in_table
      from mgolovach_370819.distr_transactions in_table
      group by in_table.user_id_in) in_table
     on user_id_in = user_id_out;

select * from mgolovach_370819.saldo_for_each_user limit 15;

DROP VIEW mgolovach_370819.saldo_for_each_user ON CLUSTER kube_clickhouse_cluster;


-- The sums for incoming and outcoming transactions by months for each user.
-- 1 - getting incomes(out), outcomes(in_table),
-- 2 - matching out, in_table by user ids,
-- 3 - grouping by user id and month, getting sum of amounts
CREATE MATERIALIZED VIEW mgolovach_370819.transaction_sum_for_each_user ON CLUSTER kube_clickhouse_cluster
            ENGINE = AggregatingMergeTree
                ORDER BY (user_id, month) POPULATE
AS
select
    out.user_id_out as user_id,
    out.month as month,
    sum(out.amount) as income_amount,
    sum(in_table.amount) as outgoing_amount
from (select out.user_id_out,
             toMonth(out.datetime)  as month,
             count(out.user_id_out) as incoming,
             sum(out.amount)        as amount
--       from mgolovach_370819.transactions out
      from mgolovach_370819.distr_transactions out
      group by out.user_id_out, toMonth(out.datetime)) out inner join
     (select in_table.user_id_in,
             toMonth(in_table.datetime) as month,
             count(in_table.user_id_in) as outcoming,
             sum(in_table.amount)       as amount
--       from mgolovach_370819.transactions in_table
      from mgolovach_370819.distr_transactions in_table
      group by in_table.user_id_in, toMonth(in_table.datetime)) in_table
     on user_id_in = user_id_out and out.month = in_table.month
group by out.user_id_out, out.month;

select * from mgolovach_370819.transaction_sum_for_each_user limit 15;

DROP VIEW mgolovach_370819.transaction_sum_for_each_user ON CLUSTER kube_clickhouse_cluster;
