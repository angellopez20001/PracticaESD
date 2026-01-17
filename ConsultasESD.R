install.packages("SPARQL")
install.packages("DT")
library(SPARQL)
library(DT)
endpoint <- "http://dayhoff.inf.um.es:3041/blazegraph/namespace/DMDblaze/sparql"

##Consulta de comprobación

query0 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>

SELECT ?s ?p ?o
WHERE {
  ?s ?p ?o .
}
LIMIT 10
"

resultado <- SPARQL(endpoint, query0)
View(resultado$results)


## CONSULTA 1: Mutaciones tratables con exon skipping
query1 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX so: <http://purl.obolibrary.org/obo/SO_>

SELECT ?mutacion ?nombreMutacion ?exon ?farmaco ?nombreFarmaco
WHERE {
  dmd_r:DuchenneMuscularDystrophy dmd_o:causadaPor ?mutacion .
  ?mutacion rdfs:label ?nombreMutacion .
  ?mutacion dmd_o:localizadaEn ?exon .
  ?exon rdf:type so:SO_0000147 .
  ?mutacion dmd_o:tratadaCon ?farmaco .
  ?farmaco rdfs:label ?nombreFarmaco .
  FILTER(?farmaco IN (dmd_r:Eteplirsen, dmd_r:Golodirsen, dmd_r:Casimersen))
}
ORDER BY ?exon
"


resultado1 <- SPARQL(endpoint, query1)
datatable(resultado1$results,
          options = list(pageLength = 10),
          caption = "Consulta 1: Mutaciones tratables con exon skipping")

## CONSULTA 2: Clasificación de mutaciones por tipo
query2 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX so: <http://purl.obolibrary.org/obo/SO_>
PREFIX biolink: <https://w3id.org/biolink/vocab/>

SELECT DISTINCT ?mutacion ?nombreMutacion ?tipoSO ?tipoMutacion ?frecuencia
WHERE {
    ?mutacion rdfs:label ?nombreMutacion ;
              dmd_o:tieneFrecuenciaAlelica ?frecuencia ;
              rdf:type ?tipoSO .
    
    FILTER(STRSTARTS(STR(?tipoSO), 'http://purl.obolibrary.org/obo/SO_'))
    
    BIND(
        IF(?tipoSO = so:SO_0000159, 'Deleción',
        IF(?tipoSO = so:SO_0001587, 'Nonsense',
        IF(?tipoSO = so:SO_1000035, 'Duplicación', 'Otro')))
        AS ?tipoMutacion
    )
}
ORDER BY DESC(?frecuencia)
"

resultado2 <- SPARQL(endpoint, query2)

datatable(resultado2$results,
          options = list(pageLength = 15),
          caption = "Consulta 2: Clasificación de mutaciones por tipo molecular")




## CONSULTA 3: Mutaciones nonsense tratables con Ataluren
query3 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX so: <http://purl.obolibrary.org/obo/SO_>

SELECT ?mutacion ?nombreMutacion ?comentario ?frecuencia ?tratamiento
WHERE {
  ?mutacion rdf:type so:SO_0001587 .  
  ?mutacion rdfs:label ?nombreMutacion .
  ?mutacion rdfs:comment ?comentario .
  ?mutacion dmd_o:tieneFrecuenciaAlelica ?frecuencia .
  ?mutacion dmd_o:tratadaCon dmd_r:Ataluren .
  
  BIND(\"Ataluren (Translarna)\" AS ?tratamiento)
}
ORDER BY DESC(?frecuencia)
"

resultado3 <- SPARQL(endpoint, query3)
datatable(resultado3$results,
          options = list(pageLength = 10),
          caption = "Consulta 3: Mutaciones nonsense tratables con Ataluren")


##CONSULTA 4: Subfenotipos musculoesqueléticos
query4 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX hp: <http://purl.obolibrary.org/obo/HP_>

SELECT ?subfenotipo ?nombreSubfenotipo ?comentario ?idHPO
WHERE {
  dmd_r:DuchenneMuscularDystrophy dmd_o:tieneFenotipo dmd_r:FenotipoMusculoesqueletico .
  dmd_r:FenotipoMusculoesqueletico dmd_o:tieneFenotipo ?subfenotipo .
  ?subfenotipo rdfs:label ?nombreSubfenotipo .
  ?subfenotipo rdfs:comment ?comentario .
  ?subfenotipo rdf:type ?idHPO .
  
  # Filtrar solo IDs de HPO
  FILTER(STRSTARTS(STR(?idHPO), \"http://purl.obolibrary.org/obo/HP_\"))
}
ORDER BY ?nombreSubfenotipo
"

resultado4 <- SPARQL(endpoint, query4)
datatable(resultado4$results,
          options = list(pageLength = 10),
          caption = "Consulta 4: Fenotipos musculoesqueléticos de DMD")


# CONSULTA 5: Mutaciones más frecuentes (>1.5%)
query5 <- "
PREFIX dmd_r: <http://dmd_recursos.um.es/>
PREFIX dmd_o: <http://dmd_ontologia.um.es/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX so: <http://purl.obolibrary.org/obo/SO_>

SELECT ?nombreMutacion ?tipoMutacion ?frecuencia ?tratamientoEspecifico
WHERE {
  dmd_r:DuchenneMuscularDystrophy dmd_o:causadaPor ?mutacion .
  ?mutacion rdfs:label ?nombreMutacion .
  ?mutacion rdf:type ?tipoSO .
  ?mutacion dmd_o:tieneFrecuenciaAlelica ?frecuencia .
  
  BIND(
    IF(?tipoSO = so:SO_0000159, \"Deleción\",
    IF(?tipoSO = so:SO_1000035, \"Duplicación\",
    IF(?tipoSO = so:SO_0001587, \"Nonsense\", \"Otra\")))
    AS ?tipoMutacion
  )
  
  OPTIONAL {
    ?mutacion dmd_o:tratadaCon ?farmaco .
    ?farmaco rdfs:label ?tratamientoEspecifico .
    FILTER(?farmaco != dmd_r:Deflazacort && ?farmaco != dmd_r:Prednisona)
  }
  
  FILTER(?frecuencia > 0.015)
}
ORDER BY DESC(?frecuencia)
"

resultado5 <- SPARQL(endpoint, query5)
datatable(resultado5$results,
          options = list(pageLength = 10),
          caption = "Consulta 5: Mutaciones más frecuentes (>1.5%)")
