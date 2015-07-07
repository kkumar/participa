Rails.application.routes.draw do
    get '/circulos/validacion', to: 'page#circles_validation', as: 'circles_validation'

    get '/comision-de-garantias-democraticas', to: 'page#guarantees', as: 'guarantees'
    get '/comision-de-garantias-democraticas/comunicacion', to: 'page#guarantees_form', as: 'guarantees_form'

    get '/gente-por-el-cambio', to: redirect('/equipos-de-accion-participativa')

    get '/responsables-finanzas-legal', to: 'page#town_legal', as: 'town_legal'

    get '/listas-autonomicas', to: 'page#list_register', as: 'list_register'
    get '/avales-candidaturas-barcelona', to: 'page#avales_barcelona', as: 'avales_barcelona'
    get '/primarias-andalucia', to: 'page#primarias_andalucia', as: 'primarias_andalucia'
    get '/listas-primarias-andaluzas', to: 'page#listas_primarias_andaluzas', as: 'listas_primarias_andaluzas'

    get '/responsables-organizacion-municipales', to: 'page#responsables_organizacion_municipales', as: 'responsables_organizacion_municipales'
    get '/responsables-municipales-andalucia', to: 'page#responsables_municipales_andalucia', as:'responsables_municipales_andalucia'
    get '/plaza-podemos-municipal', to: 'page#plaza_podemos_municipal', as:'plaza_podemos_municipal'
    get '/portal-transparencia-cc-estatal', to: 'page#portal_transparencia_cc_estatal', as:'portal_transparencia_cc_estatal'
    get '/mujer-igualdad', to: 'page#mujer_igualdad', as:"mujer_igualdad"
    get '/solicitud-consulta-ciudadana-candidatura-unidad-popular', to: 'page#alta_consulta_ciudadana', as:"alta_consulta_ciudadana"
    get '/representantes-electorales-extranjeros', to: 'page#representantes_electorales_extranjeros', as:"representantes_electorales_extranjeros"
    get '/responsables-areas-cc-autonomicos', to: 'page#responsables_areas_cc_autonomicos', as:"responsables_areas_cc_autonomicos"
    get '/boletin-correo-electronico', to: 'page#boletin_correo_electronico', as:"boletin_correo_electronico"
    get '/responsable-web-autonomico', to: 'page#responsable_web_autonomico', as: 'responsable_web_autonomico'
    
    get '/comparte-el-cambio', to: 'page#demo', as: 'demo'
    get '/comparte-el-cambio/compartir-casa', to: 'page#offer_hospitality', as: 'offer_hospitality'
    get '/comparte-el-cambio/encuentra-casa', to: 'page#find_hospitality', as: 'find_hospitality'
    get '/comparte-el-cambio/compartir-coche-sevilla', to: 'page#share_car_sevilla', as: 'share_car_sevilla'
    get '/comparte-el-cambio/encuentra-viaje-sevilla', to: 'page#find_car_sevilla', as: 'find_car_sevilla'
    get '/comparte-el-cambio/compartir-coche-doshermanas', to: 'page#share_car_doshermanas', as: 'share_car_doshermanas'
    get '/comparte-el-cambio/encuentra-viaje-doshermanas', to: 'page#find_car_doshermanas', as: 'find_car_doshermanas'
    get '/comparte-el-cambio/valoracion-propietarios', to: 'page#comparte_cambio_valoracion_propietarios', as: 'comparte_cambio_valoracion_propietarios'
    get '/comparte-el-cambio/valoracion-usuarios', to: 'page#comparte_cambio_valoracion_usuarios', as: 'comparte_cambio_valoracion_usuarios'

    get '/apoderados-campana-autonomica-andalucia', to: 'page#apoderados_campana_autonomica_andalucia', as: 'apoderados_campana_autonomica_andalucia'
    get '/candidaturas-primarias-autonomicas', to: 'page#candidaturas_primarias_autonomicas', as: 'candidaturas_primarias_autonomicas'
    get '/listas-primarias-autonomicas', to: 'page#listas_primarias_autonomicas', as: 'listas_primarias_autonomicas'
    get '/avales-candidaturas-primarias', to: 'page#avales_candidaturas_primarias', as: 'avales_candidaturas_primarias'
    get '/iniciativa-ciudadana', to: 'page#iniciativa_ciudadana', as: 'iniciativa_ciudadana'

    get '/cuentas-consejos-autonomicos-33', to: 'page#cuentas_consejos_autonomicos', as: 'cuentas_consejos_autonomicos'
    get '/condiciones-uso-correo-34', to: 'page#condiciones_uso_correo', as: 'condiciones_uso_correo'

end
