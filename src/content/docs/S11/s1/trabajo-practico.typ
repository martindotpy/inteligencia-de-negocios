#import "@preview/versatile-apa:7.2.0": versatile-apa as apa-style
#import "@preview/callisto:0.2.5"
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.6": mitex

// Style
#show: codly-init.with()
#show: apa-style.with(
  font-size: 12pt,
)
#show heading.where(level: 1): h => {
  pagebreak()
  h
}
#codly(languages: codly-languages)

// Fixes conflict with codly's and apa-style's figure configuration
#show figure.where(kind: raw): set block(width: auto)
#set raw(block: false)


// Configuration
#set page(numbering: none, paper: "a4")
#set text(lang: "es", font: "Times New Roman")
#set figure(placement: none)
#set table(align: left)
#set image(fit: "contain")


// Cover
#page()[
  #set align(center)
  #set text(size: 14pt)

  #image("/src/assets/img/utp-logo.png", width: 80%)

  #v(0.5cm)
  *UNIVERSIDAD TECNOLÓGICA DEL PERÚ*
  #v(0.125cm)

  *S11.s1 — Trabajo Práctico*
  #v(1cm)

  *Curso*\
  Inteligencia de Negocios
  #v(0.5cm)

  *Sección*\
  31677
  #v(0.5cm)

  *Integrantes*\
  #table(
    [Carrillo Barba, Alexis Martín], [U21218567],
    [Olivos Suxe, Neyser Alexander], [U22315776],
    [Pecho Santos, Manuel Angel], [U76075762],
    [Ramos Yampufe, Martin Alexander], [U22214724],
    columns: (55%, 25%),
    gutter: 0.25cm,
    stroke: none,
  )
  #v(0.5cm)

  *Docente*\
  Tapia Ore, Willy Alexander

  #v(1fr)
  Perú

  #v(0.5cm)
  #datetime.today().year()

]


// Configuration post cover
#set page(numbering: "1")

#show table.cell.where(y: 0): strong


// Sections
#outline()

#show heading.where(level: 1): h => {
  colbreak()
  h
}
#show table.cell.where(y: 0): it => block(it)

= Introducción

En la última década, el volumen de datos generados a nivel global ha
experimentado un crecimiento exponencial. Se estima que el 90% de todos los
datos existentes se han generado únicamente en los últimos dos años. Este
fenómeno ha dado lugar al concepto de Big Data, definido originalmente por Doug
Laney a principios de los años 2000 mediante tres dimensiones fundamentales:
volumen, velocidad y variedad (las 3Vs). Posteriormente, la industria evolucionó
hacia un modelo de 5Vs al incorporar la veracidad y el valor como dimensiones
críticas para transformar los datos en ventajas estratégicas.

El presente trabajo práctico tiene como objetivo aplicar estos conceptos
mediante la caracterización de un problema de negocio real que requiere Big
Data. Para ello, se ha seleccionado a Olist, una empresa brasileña de comercio
electrónico, y su conjunto de datos público disponible en Kaggle. A través del
análisis de las 5Vs, se describirá un problema de negocio específico , la alta
tasa de retraso en las entregas, y se propondrá una arquitectura tecnológica
para su solución.

= Descripción de la Empresa y el Dataset

== Olist Store

Olist es el mayor departamento digital en marketplaces brasileños, con sede en
São Paulo, Brasil. La empresa actúa como un intermediario que conecta a pequeños
comercios de todo Brasil con canales de venta en línea mediante un solo
contrato. Los comerciantes pueden vender sus productos a través de Olist Store,
y la empresa se encarga de la logística de entrega mediante socios
transportistas.

== Dataset: Brazilian E-Commerce Public Dataset by Olist

El dataset utilizado en este trabajo es el Brazilian E-Commerce Public Dataset
by Olist, publicado en Kaggle bajo el siguiente enlace: #link(
  "https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce",
)

Este conjunto de datos contiene información de más de 100,000 pedidos realizados
entre 2016 y 2018 en múltiples marketplaces de Brasil. Los datos han sido
anonimizados y las referencias a empresas y socios han sido reemplazadas por
nombres de casas de Game of Thrones.

El dataset se compone de 8 archivos CSV que conforman un esquema relacional:

#figure(
  table(
    columns: (auto, auto, auto),
    table.header[Archivo][Filas][Descripción],
    [olist_customers_dataset.csv],
    [~96,000],
    [Datos de clientes (ID, código postal, ciudad, estado)],
    [olist_orders_dataset.csv],
    [~100,000],
    [Órdenes (estado, fechas de compra, aprobación y entrega)],
    [olist_order_items_dataset.csv],
    [~112,000],
    [Ítems por orden (producto, vendedor, precio, flete)],
    [olist_order_payments_dataset.csv],
    [~104,000],
    [Pagos (tipo, cuotas, valor)],
    [olist_order_reviews_dataset.csv],
    [~100,000],
    [Reseñas (score, título, comentario, fechas)],
    [olist_products_dataset.csv],
    [~33,000],
    [Productos (categoría, dimensiones, peso)],
    [olist_sellers_dataset.csv],
    [~3,000],
    [Vendedores (ID, código postal, ciudad, estado)],
    [product_category_name_translation.csv],
    [~74],
    [Traducción portugués-inglés de categorías],
    table.hline(),
  ),
  caption: [Composición del dataset de Olist],
)

= Problema de Negocio

El problema de negocio identificado es el siguiente: *"Alta tasa de retraso en
las entregas que impacta negativamente en la satisfacción del cliente, generando
reseñas desfavorables , con puntuaciones iguales o inferiores a 2 en la escala
de 1 a 5, y provocando una pérdida estimada de 2.5 millones de reales brasileños
(BRL) anuales debido a devoluciones, reembolsos y daño a la reputación de la
marca."*

El dataset revela que aproximadamente el 10% de las órdenes presentan retrasos
respecto a la fecha estimada de entrega. Este problema involucra múltiples
dimensiones: la ubicación geográfica de clientes y vendedores, la categoría del
producto, el desempeño del transportista, el valor del flete y la temporalidad
de la compra.

La complejidad del problema radica en la necesidad de correlacionar estas
variables heterogéneas en tiempo real para construir un modelo predictivo que
permita anticipar retrasos y tomar acciones correctivas antes de que afecten al
cliente.

= Análisis de las 5Vss

A continuación, se caracteriza el problema descrito bajo el modelo de las 5Vs
del Big Data:

== Volumen

El dataset en su estado original ocupa aproximadamente 3 GB y contiene más de
100,000 registros de órdenes. Sin embargo, para un despliegue a escala de
producción, se proyectan los siguientes volúmenes:

#figure(
  table(
    columns: (auto, auto, auto),
    table.header[Fuente de datos][Volumen diario estimado][Volumen anual
      proyectado],
    [Órdenes y transacciones], [~2.5 GB], [~0.9 TB],
    [Clickstream (e-commerce)], [~5 GB], [~1.8 TB],
    [Tracking de entregas (geolocalización)], [~1.5 GB], [~0.5 TB],
    [Reseñas y comentarios de clientes], [~0.5 GB], [~0.2 TB],
    [Datos de sensores IoT (logística)], [~3 GB], [~1.1 TB],
    table.hline(stroke: 0.5pt),
    [*Total*], [*~12.5 GB/día*], [*~4.5 TB/año*],
    table.hline(),
  ),
  caption: [Proyección de volumen de datos a escala de producción],
)

El volumen total estimado asciende a aproximadamente 12.5 GB por día, lo que
equivale a unos 4.5 TB al año. Esta magnitud supera la capacidad de
procesamiento de bases de datos relacionales tradicionales y justifica el uso de
tecnologías Big Data.

== Velocidad

La velocidad requerida para el procesamiento se clasifica en tres niveles:

- Streaming en tiempo real para la captura y procesamiento de datos de tracking
  de entregas, alertas de retraso inminente y detección de anomalías en la
  cadena logística, con una latencia requerida inferior a 5 segundos.
- Micro-batches cada 5 minutos para la actualización del estado de las órdenes,
  sincronización de inventarios y agregación de métricas operativas para
  dashboards en tiempo casi real.
- Batch diario para el entrenamiento y reentrenamiento de modelos predictivos
  como Random Forest y XGBoost, la generación de reportes semanales de desempeño
  de vendedores y la actualización de paneles de KPIs estratégicos.

== Variedad

Los datos a integrar presentan una alta heterogeneidad de formatos:

#figure(
  table(
    columns: (auto, auto, auto),
    table.header[Tipo][Fuentes][Formato],
    [Estructurados],
    [Tablas de órdenes, clientes, pagos, productos, vendedores],
    [CSV, SQL],
    [Semiestructurados],
    [Logs de servidor web, JSON de API de tracking],
    [JSON, XML, log],
    [No estructurados],
    [Reseñas de texto libre, títulos de reseñas, imágenes de productos],
    [Texto plano, JPG/PNG],
    table.hline(),
  ),
  caption: [Variedad de formatos de datos en el ecosistema Olist],
)

Mención especial merecen los datos no estructurados provenientes de las reseñas
de clientes, que contienen texto libre en portugués con opiniones, quejas y
sugerencias que requieren técnicas de procesamiento de lenguaje natural (NLP)
para su análisis.

== Veracidad

El análisis exploratorio del dataset revela diversos desafíos relacionados con
la calidad de los datos:

#figure(
  table(
    columns: (auto, auto, auto),
    table.header[Problema de calidad][Magnitud][Estrategia de mitigación],
    [Fechas de entrega faltantes en delivered_customer_date],
    [2,965 registros (~3%)],
    [Imputación condicional basada en la mediana de días de entrega por estado],
    [Reseñas sin comentario escrito],
    [58,259 registros (~58%)],
    [Análisis basado únicamente en el score numérico; NLP solo sobre comentarios
      existentes],
    [Categorías de producto vacías],
    [610 productos (~1.8%)],
    [Asignación por similitud de nombre del producto o exclusión del análisis],
    [Sesgo en las reseñas (positividad)],
    [Media ~4.0/5.0],
    [Balanceo de clases para modelos predictivos; análisis de sentimiento
      ponderado],
    [Inconsistencias en nombres de ciudades],
    [Múltiples variantes (ej. "sao paulo", "são paulo", "sp")],
    [Pipeline de estandarización geoespacial con diccionario de normalización],
    [Duplicados potenciales de clientes],
    [Clientes con mismo zip code y ciudad pero distinto ID],
    [Algoritmo de fuzzy matching para deduplicación],
    table.hline(),
  ),
  caption: [Retos de veracidad y estrategias de mitigación],
)

La gestión adecuada de estos problemas de calidad es fundamental para garantizar
la confiabilidad de los análisis y modelos predictivos derivados.

== Valor

El valor estratégico y financiero del proyecto se cuantifica en los siguientes
términos:

#figure(
  table(
    columns: (auto, auto),
    table.header[Beneficio][Impacto económico anual estimado],
    [Reducción de devoluciones y reembolsos por retrasos], [1.2 MM BRL],
    [Incremento en retención de clientes por mejor experiencia], [0.8 MM BRL],
    [Optimización de rutas de entrega mediante analytics predictivo],
    [0.3 MM BRL],
    [Reducción de costos operativos de atención al cliente], [0.2 MM BRL],
    table.hline(stroke: 0.5pt),
    [*ROI total*], [*2.5 MM BRL/año*],
    table.hline(),
  ),
  caption: [Valor estratégico y financiero del proyecto Big Data en Olist],
)

Además del impacto financiero directo, el proyecto genera valor estratégico al
permitir:

- Ventaja competitiva ya que Olist puede ofrecer a sus sellers un panel de
  predicción de retrasos, diferenciándose de otros marketplaces.
- Toma de decisiones basada en datos al identificar patrones de retraso por
  región, temporada o transportista y negociar mejores acuerdos logísticos.
- Personalización del servicio mediante notificaciones proactivas a clientes
  frecuentes sobre el estado de sus entregas, mejorando la experiencia de
  compra.

= Arquitectura Big Data Propuesta

La arquitectura propuesta para abordar el problema sigue un flujo de
procesamiento basado en el modelo Lambda, combinando procesamiento por lotes
(batch) y en tiempo real (streaming):

#figure(
  table(
    columns: (auto, auto),
    table.header[Capa][Componentes y función],
    [Ingesta],
    [Apache Kafka: Captura de flujos de datos en tiempo real (órdenes, tracking,
      reseñas) desde las fuentes],
    [Procesamiento batch],
    [Apache Hadoop HDFS: Almacenamiento distribuido del histórico de datos
      (petabytes). Apache Spark (batch): Procesamiento de datos históricos para
      entrenamiento de modelos ML],
    [Procesamiento streaming],
    [Apache Spark Streaming: Procesamiento de flujos en tiempo real para
      detección temprana de retrasos],
    [Almacenamiento analítico],
    [Data Lake (HDFS/S3): Almacenamiento unificado de datos crudos y
      procesados],
    [Machine Learning],
    [Modelo predictivo Random Forest / XGBoost para predicción de retrasos en
      entregas basado en variables históricas (distancia, categoría,
      transportista, precio de flete, temporada)],
    [Visualización],
    [Power BI / Tableau: Dashboards interactivos con KPIs como porcentaje de
      entregas a tiempo, score promedio por vendedor y tasa de retraso por
      categoría de producto],
    table.hline(),
  ),
  caption: [Arquitectura Big Data propuesta (modelo Lambda)],
)

= Conclusiones

El análisis del caso de Olist permite extraer las siguientes conclusiones:

1. El Big Data no se define únicamente por la cantidad de datos almacenados,
  sino por la capacidad de transformar un ecosistema masivo y caótico ,
  caracterizado por las dimensiones de volumen, velocidad y variedad , en
  decisiones empresariales confiables (veracidad) y rentables (valor).

2. El problema de los retrasos en las entregas en Olist constituye un caso
  paradigmático de aplicación de Big Data, pues involucra las 5Vs de manera
  integral: grandes volúmenes de datos transaccionales y de tracking,
  procesamiento en tiempo real para alertas tempranas, integración de formatos
  diversos (estructurados, semiestructurados y no estructurados), desafíos
  significativos de calidad de datos y un impacto financiero cuantificable.

3. La arquitectura Lambda propuesta, combinando Apache Kafka para la ingesta,
  Apache Spark para el procesamiento batch y streaming, y un data lake como
  repositorio unificado, ofrece una solución escalable y robusta para abordar la
  complejidad del problema.

4. El dataset público de Olist, disponible en Kaggle, demuestra que incluso con
  datos abiertos es posible realizar un análisis exhaustivo de las 5Vs y
  construir propuestas de valor basadas en Big Data, nivelando el campo de juego
  para pequeñas y medianas empresas que buscan competir con grandes
  corporaciones.
