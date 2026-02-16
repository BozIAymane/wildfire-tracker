import datetime
import logging
import json
import os
import requests
import azure.functions as func
from azure.storage.blob import BlobServiceClient

# Cette fonction est déclenchée par un Timer (CRON) toutes les 5 minutes
# Elle suit le modèle ETL : Extract (Récupérer), Transform (Traiter), Load (Charger)
def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    # ==============================================================================
    # 1. ETAPE EXTRACT (Extraction) : Récupération des données depuis la NASA
    # ==============================================================================
    url = "https://eonet.gsfc.nasa.gov/api/v3/events?category=wildfires"
    try:
        logging.info("Début de la récupération des données NASA...")
        response = requests.get(url)
        response.raise_for_status() # Vérifie s'il y a une erreur HTTP (ex: 404, 500)
    except requests.exceptions.RequestException as e:
        logging.error(f"Échec de la récupération des données : {e}")
        return

    data = response.json()
    events = data.get('events', [])
    logging.info(f"{len(events)} événements bruts récupérés.")

    # ==============================================================================
    # 2. ETAPE TRANSFORM (Transformation) : Nettoyage et Normalisation
    # ==============================================================================
    normalized_events = []
    for event in events:
        # On récupère la géométrie (position du feu)
        geometries = event.get('geometry', [])
        if not geometries:
            continue
        
        # On prend la dernière position connue (la plus récente)
        geo = geometries[-1] 
        coords = geo.get('coordinates', []) # Format NASA : [Longitude, Latitude]
        date = geo.get('date', '')

        if coords:
             # IMPORTANT : Leaflet utilise [Latitude, Longitude].
             # NASA donne [Longitude, Latitude]. Il faut donc inverser.
             lat = coords[1]
             lng = coords[0]

             # Création d'un objet propre avec seulement les infos nécessaires
             normalized_events.append({
                "id": event.get('id'),
                "title": event.get('title'),
                "coordinates": [lat, lng], # Coordonnées corrigées pour la carte
                "date": date
            })
    
    logging.info(f"{len(normalized_events)} événements traités et prêts à être stockés.")

    # ==============================================================================
    # 3. ETAPE LOAD (Chargement) : Stockage dans Azure Blob Storage
    # ==============================================================================
    # Récupération de la chaîne de connexion sécurisée depuis les variables d'environnement
    connect_str = os.getenv('AzureWebJobsStorage')
    if not connect_str:
        logging.error("AzureWebJobsStorage connection string not found.")
        return

    try:
        # Connexion au service Blob Storage
        blob_service_client = BlobServiceClient.from_connection_string(connect_str)
        container_name = "data"
        
        # Création du conteneur s'il n'existe pas (avec accès public pour le Frontend)
        container_client = blob_service_client.get_container_client(container_name)
        if not container_client.exists():
            container_client.create_container(public_access='blob')

        # Upload du fichier JSON (écrasement de l'ancien fichier pour mise à jour temps réel)
        blob_client = container_client.get_blob_client("wildfires.json")
        blob_client.upload_blob(json.dumps(normalized_events), overwrite=True)
        
        logging.info(f"SUCCÈS : Uploaded {len(normalized_events)} events to blob storage.")
        
    except Exception as e:
        logging.error(f"Erreur lors de l'interaction avec Blob Storage : {e}")
