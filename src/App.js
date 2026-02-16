import { useState, useEffect } from 'react';
import Map from './components/Map';
import Loader from './components/Loader';
import { Header } from './components/Header';

// Use a placeholder or environment variable. 
// For this task, we will try to use the environment variable if available, 
// otherwise default to a strict placeholder the user must replace.
const DATA_URL = "https://wildfirestore2534.blob.core.windows.net/data/wildfires.json";

function App() {
  const [eventData, setEventData] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const fetchEvents = async () => {
      setLoading(true)
      try {
        const res = await fetch(DATA_URL)
        if (!res.ok) {
          throw new Error(`HTTP error! status: ${res.status}`);
        }
        const events = await res.json()
        setEventData(events)
      } catch (error) {
        console.error("Failed to fetch data", error)
        // Fallback or empty state
      }
      setLoading(false)
    }
    fetchEvents()
  }, [])
  return (
    <div className="App">
      <Header />
      {!loading ? <Map eventData={eventData} /> : <Loader />}
    </div>
  );
}

export default App;