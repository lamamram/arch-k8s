<?php
echo "<h1>Hello World from PHP8.4-FPM</h1>";
echo 'Version PHP courante : ' . phpversion();

//echo '<pre>';
// try{
//   // ici on ne peut utiliser le fichier .env dans le conteneur PHP-FPM
//   // puisque les requêtes PHP venus du nginx ne contiennent l'environnement chargé avec le lancement de FPM lui-même !!! 
//   $conn = new \PDO('mysql:host=stack-php-mariadb;dbname=test', 'test', 'roottoor');
//   $sth = $conn->prepare('SELECT * FROM pays');
//   $sth->execute();
//   $checks = $sth->fetchAll(PDO::FETCH_ASSOC);
//   foreach ($checks as $check) {

//   print_r($check);
//   }
// }
// catch(\Exception $e){
//     print_r($e);
// }
// echo '</pre>';
?>
