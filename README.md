# **Deploy a Secure "Hello World" App on Azure Kubernetes Service (AKS) with a Non-Root User**

This guide walks you through:
1. **Creating an AKS cluster**
2. **Building and pushing a secure Docker image** to **Azure Container Registry (ACR)**
3. **Deploying the application to AKS** with **non-root security best practices**
4. **Fixing container registry permission issues**
5. **Connecting to the Kubernetes Dashboard**
6. **Accessing the shell of a running pod**

---

## **Prerequisites**
Before starting, ensure you have:
- **Azure CLI** installed → [Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **kubectl** installed → [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker** installed → [Install Guide](https://docs.docker.com/get-docker/)
- An **Azure subscription** → [Sign Up](https://azure.com/free)

---

## **Step 1: Create an AKS Cluster**
### **1.1 Log in to Azure**
```sh
az login
```
If you have multiple subscriptions, set the correct one:
```sh
az account set --subscription "<your-subscription-id>"
```

### **1.2 Create a Resource Group**
```sh
az group create --name aks-resource-group --location eastus
```

### **1.3 Create an AKS Cluster**
```sh
az aks create --resource-group aks-resource-group \
  --name myAKSCluster \
  --node-count 2 \
  --enable-managed-identity \
  --generate-ssh-keys
```
✅ Creates an **AKS cluster with 2 nodes** and **managed identity**.

### **1.4 Connect to the AKS Cluster**
```sh
az aks get-credentials --resource-group aks-resource-group --name myAKSCluster
```
✅ Downloads credentials and sets up `kubectl` access.

### **1.5 Verify the Cluster**
```sh
kubectl get nodes
```
✅ Should display two worker nodes.

---

## **Step 2: Create a "Hello World" Application**
### **2.1 Create a Project Directory**
```sh
mkdir hello-world-aks && cd hello-world-aks
```

### **2.2 Create the Application File**
```sh
nano server.js
```
Paste:
```javascript
const http = require('http');
const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello World from AKS!\n');
});
server.listen(3000, () => {
    console.log('Server running on port 3000');
});
```

---

## **Step 3: Create a Secure Docker Image**
### **3.1 Create a Dockerfile**
```sh
nano Dockerfile
```
Paste:
```dockerfile
FROM node:18-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY server.js .
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 3000
CMD ["node", "server.js"]
```
✅ **Security Best Practices Applied:** Non-root user, proper permissions.

---

## **Step 4: Build and Push the Docker Image to ACR**
### **4.1 Create an Azure Container Registry (ACR)**
```sh
az acr create --resource-group aks-resource-group \
  --name myacrregistry168168 --sku Basic
```

### **4.2 Log in to ACR**
```sh
az acr login --name myacrregistry168168
```

### **4.3 Build and Push the Docker Image**
```sh
docker build -t myacrregistry168168.azurecr.io/hello-world:latest .
docker push myacrregistry168168.azurecr.io/hello-world:latest
```

---

## **Step 5: Fix Container Registry Permissions**
If you get **401 Unauthorized** while pulling images, run:
```sh
az aks update --resource-group aks-resource-group --name myAKSCluster --attach-acr myacrregistry168168
```
✅ Grants AKS permission to pull images from ACR.

Restart the deployment:
```sh
kubectl rollout restart deployment hello-world
```

---

## **Step 6: Deploy to AKS**
### **6.1 Create a Deployment File**
```sh
nano deployment.yaml
```
Paste:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
        - name: hello-world
          image: myacrregistry168168.azurecr.io/hello-world:latest
          ports:
            - containerPort: 3000
```

### **6.2 Deploy the Application**
```sh
kubectl apply -f deployment.yaml
```

### **6.3 Expose the Service**
```sh
nano service.yaml
```
Paste:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
spec:
  selector:
    app: hello-world
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
```

Deploy the service:
```sh
kubectl apply -f service.yaml
```

Get the external IP:
```sh
kubectl get service hello-world-service
```
✅ Open the **EXTERNAL-IP** in a browser.

---

## **Step 7: Connect to the Kubernetes Dashboard**
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin-binding --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
kubectl proxy
```
Open:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## **Step 8: Access a Running Pod's Shell**
```sh
kubectl get pods
kubectl exec -it <pod-name> -- /bin/sh
```
For a **multi-container pod**:
```sh
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh
```

---

## **Step 9: Cleanup (Optional)**
```sh
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
az aks delete --resource-group aks-resource-group --name myAKSCluster --yes --no-wait
az acr delete --resource-group aks-resource-group --name myacrregistry168168 --yes
```

✅ **AKS cluster and resources removed successfully!** 🚀
