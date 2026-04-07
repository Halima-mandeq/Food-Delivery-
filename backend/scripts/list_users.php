<?php
require_once '../config/db.php';
$stmt = $pdo->query("SELECT email, role FROM users");
echo json_encode($stmt->fetchAll(), JSON_PRETTY_PRINT);
?>
