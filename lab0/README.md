In every .yaml file change namespace to your login
<br>
<br>
Change image name in lab0-deployment.yaml, change "<your_login>" template your login
<br>
<br>
Also remember to set YOUR password in container arguments of deployment:
<br>
"--NotebookApp.token='your_password'" 

Copy all files to remote server and apply configs:
<br>
<br>
kubectl apply -f lab0-config-map.yaml
<br>
kubectl apply -f lab0-deployment.yaml
<br>
kubectl apply -f lab0-service.yaml


<br> 
Task 5: 
<br> 
After everything is running, type command with your pod name:
<br>
<strong>kubectl logs pod/lab0-jupyter-1234 --timestamps > lab0-jupyter.log</strong>

<br>
<br>

Task 6:
<br>
Edit file "lab0-ls-lah.sh", set name of your pod
<br>
After that following command should print single file "jupyter_notebook_config.py":
<br>
<strong>bash lab0-ls-lah.sh</strong>


To check if "jupyter_notebook_config.py" correctly overridden (contains only 2 lines):
<br>
<strong>kubectl exec <pod_name> -- cat .jupyter/jupyter_notebook_config.py<strong>