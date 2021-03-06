<?php
declare(strict_types = 1);
require_once __DIR__.'/src/AutoLoad.php';

if ($auth->isLoggedIn()) {
    $auths       = new \AccountManager\Auths($db, $auth);
    $renderArray = array('auths' => $auths);

    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'add':
                $auths->add($_POST['label']);
                break;
        }
    }
    echo $twig->render('pages/auths/index.twig', $renderArray);
} else {
    header('Location: login.php');
}
