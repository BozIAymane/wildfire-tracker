# Wildfire Tracker Project 🌲🔥

A cloud-based web application for tracking wildfires in real-time. This project leverages **Azure Functions** for serverless backend processing, **Azure Blob Storage** for data persistence, and a **React** frontend for visualizing wildfire events on an interactive map.

## 🚀 Live Demo
[View Live Project](https://wildfirestore2534.z1.web.core.windows.net/)

## 🏗 Architecture
The solution follows a serverless architecture on Microsoft Azure:

1.  **Backend (Azure Function)**:
    -   Periodically fetches wildfire data from NASA EONET API.
    -   Processes and stores the data in **Azure Blob Storage** (`wildfires.json`).
    
2.  **Frontend (React)**:
    -   Hosted as a static web app (or on Azure Storage Static Website).
    -   Fetches the JSON data directly from Blob Storage.
    -   Displays events on a map using **Leaflet** (OpenStreetMap).

## 🛠 Prerequisites

-   **Node.js** (v14 or higher)
-   **Python** (3.8 or higher)
-   **Azure CLI** (for deployment)
-   **Azure Functions Core Tools** (for local backend debugging)

## 📥 Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/wildfire-project.git
    cd wildfire-project
    ```

2.  **Install Frontend Dependencies**:
    ```bash
    npm install
    ```

3.  **Install Backend Dependencies**:
    ```bash
    cd backend
    pip install -r requirements.txt
    ```

## 🏃‍♂️ Running Locally

### Backend (Optional if using live data)
To run the Azure Function locally:
```bash
cd backend
func start
```

### Frontend
To start the React application:
```bash
npm start
```
The app will open at `http://localhost:3000`.

## ☁️ Deployment

A PowerShell script `deploy_v2.ps1` is provided to automate the deployment to Azure.

1.  **Login to Azure**:
    ```powershell
    az login
    ```

2.  **Run the Deployment Script**:
    ```powershell
    ./deploy_v2.ps1
    ```
    *Note: This script creates a Resource Group, Storage Account, Function App, and Static Web App.*

## 📂 Project Structure

```
wildfire-project/
├── backend/                # Azure Functions (Python)
│   ├── FetchWildfires/     # Function code
│   └── requirements.txt    # Python dependencies
├── src/                    # React Source Code
│   ├── components/         # UI Components (Map, Loader, Header)
│   ├── App.js              # Main Component
│   └── index.js            # Entry Point
├── public/                 # Static Assets (index.html, icons)
├── deploy_v2.ps1           # Azure Deployment Automation Script
└── package.json            # Project Metadata & Dependencies
```

## 📝 Configuration

-   **Data Source**: The frontend currently points to a specific Azure Blob Storage URL in `src/App.js`. Update `DATA_URL` if you deploy to your own storage account.
-   **Map Settings**: Default center and zoom levels can be adjusted in `src/components/Map.js`.


## 📜 License
This project is open-source and available under the [MIT License](LICENSE).

## 👤 Author

**Aymane Bozian**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/aymane-bozian/)
