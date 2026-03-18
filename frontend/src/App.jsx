import { useEffect, useState } from "react"




function App() {
  const [planes, setPlanes] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)


  useEffect(()=>{
    fetch("http://localhost:8080/api/planes").then(resp=>{
      if(!resp.ok) throw new Error("error al obtener planes")
      return resp.json()  

    }).then(data=>{
      setPlanes(data)
      setLoading(false)



    }).catch(ex=>{
      setError(ex.message)
      setLoading(false)


    })


  },[])

  return (
    <div>
      <h1>SPA Relax</h1>
      {loading && <p>Cargando planes...</p>}
      {error && <p>Error: {error}</p>}


      <ul>
        {planes.map(plan=>(
          <li key={plan.id}>
            <h2>{plan.nombre}</h2>
            <p>{plan.descripcion}</p>
            <strong>{plan.precio}</strong>
          </li>


        ))}



      </ul>


    </div>
    
  )
}

export default App
