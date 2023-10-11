- > Para que sirve el `ProjectList.sol`?
  - No se puede absorver por Pool? Porque ahi ya hay giladas de projects que se aceptan y que no
- > `Pool.sol`

  - supportProjects:

  *
  * @custom:problema cualquiera activa Suportear projectos!
  * @custom:discusion Eso deberia ser con el Owner, aca entra la GNOSIS_SAFE
  * @custom:discusion Para esto es el MIME_TOKEN, para suportear proyectos, quiza se tenga que aplocar pero directo en la POOL
  * Emitiendo X cantidad de shares que este asociada a la cantidad de tokens de governanza, y que haya un limite , pero que limita que haya gente que vote 2 veces?
  * Y como garantizamos el conviction voting? Salvo que sea la POOL y la multisig quien aloque los tokens de voto a los usuarios o que haya un airdrop por cada
  
  - `OwnableProjectList` se puede intergar en POOL, asi nos evitamos llamadas externas cada vez que se quiera hacer algo
  - Agregar el sistema de support, capaz con alguna cosa tipo shares o algo por ronda que se vayan emitiendo (las claimea 1-1 el usuario y funcionen como los mimetokens)

 - Los usuarios tienen que hacer stake (del token de governanza)
    - Habria que hacer vainas para que se haga el stake
 - Le falta funcion de retiro de balance (??) [falso]

- > Manager.sol
    - createPool:
    * Que muestre los parametros que se usan aca en la pool asi se puede entender con mas claridad
    * Que se cree directamente la GNOSIS aca
    * QUe tebfab la opcion de elegir si un multisig o un address que ellos pongan




