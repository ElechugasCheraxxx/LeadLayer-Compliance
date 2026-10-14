# Registro RNPDP — Instrucciones

Registro Nacional de Protección de Datos Personales (MINJUSDH, Perú)
Obligatorio antes de operar según Art. 27 Ley 29733.

## Costo y tiempo
- Costo: ~$50–$100 USD (tasa administrativa)
- Tiempo: 3–5 días hábiles
- Modalidad: online

## URL
https://www.minjus.gob.pe/registro-nacional-de-proteccion-de-datos-personales/

## Datos a registrar

### Base de datos 1 — Usuarios de la extensión
- **Nombre:** LeadLayer Extension Users
- **Finalidad:** Prestación del servicio de enriquecimiento; mejora del motor de datos
- **Categorías de datos:** Email, nombre, datos de comportamiento de navegación (páginas soportadas), preferences de consent
- **Destinatarios:** Ninguno (datos internos del servicio)
- **Transferencias internacionales:** Supabase (USA), Railway (USA) — bajo cláusulas contractuales tipo
- **Plazo de conservación:** Duración del servicio + 30 días

### Base de datos 2 — Perfiles enriquecidos (motor interno)
- **Nombre:** LeadLayer Enrichment Engine
- **Finalidad:** Motor de consulta de datos profesionales públicos; no se comercializa como dataset
- **Base legal:** Art. 13 (interés legítimo) + Art. 14 (fuentes de acceso público)
- **Categorías de datos:** Nombre profesional, email laboral, cargo, empresa, URL de LinkedIn
- **Destinatarios:** Clientes B2B que realizan consultas individuales (no se transfieren datasets)
- **Derecho de opt-out:** leadlayer.io/opt-out (suppression list operativa)
- **Plazo de conservación:** Indefinido (motor de consulta); suprimible a solicitud

### Base de datos 3 — Registros de consent
- **Nombre:** LeadLayer Consent Records
- **Finalidad:** Registro inmutable de consents para auditoría regulatoria
- **Categorías de datos:** User ID, tipos de consent, timestamps, IP, versión de ToS
- **Conservación:** Indefinida (log de auditoría)

## Checklist antes de registrar

- [ ] ToS publicados en leadlayer.io/terms
- [ ] Privacy Policy publicada en leadlayer.io/privacy
- [ ] Portal opt-out operativo en leadlayer.io/opt-out
- [ ] DPA disponible para descarga
- [ ] ConsentModal implementado en extensión
- [ ] suppression_list activa y verificada con endpoint /opt-out
- [ ] consent_records con registro inmutable (migración 003 ejecutada)

## Post-registro

Guardar número de registro RNPDP recibido.
Incluirlo en:
- Privacy Policy (sección "Responsable del tratamiento")
- ToS (sección "Governing Law")
- Respuestas a solicitudes de derechos ARCO

## Renovación

El registro debe renovarse o actualizarse si cambia:
- La finalidad del tratamiento
- Las categorías de datos procesados
- Los destinatarios internacionales

Revisar anualmente.
