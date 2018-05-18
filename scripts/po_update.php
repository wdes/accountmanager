#!/usr/bin/php
<?php
/**
 * @license http://unlicense.org/UNLICENSE The UNLICENSE
 * @author William Desportes <williamdes@wdes.fr>
 */
$po_file = realpath(__DIR__."/../po/account-manager.pot");
$mappings = new stdClass();
$mappings->mappings = array();
$mappings->replacements = array();

if (is_file(__DIR__."/../tmp/mapping.json"))
    $mappings = json_decode(file_get_contents(__DIR__."/../tmp/mapping.json"));

function poupdate($po_file) {
    global $mappings;
    $pot_contents = file_get_contents($po_file);
    foreach($mappings->replacements as $replacement ) {
        $pot_contents = str_replace($replacement->from, $replacement->to, $pot_contents);
    }
    // Replace filename by name
    $pot_contents = preg_replace_callback(
        '@([0-9a-f]{2}\/[0-9a-f]*.php):([0-9]*)@',
        function ($matchs) {
            global $mappings;
            $line = intval($matchs[2]);
            $replace = $mappings->mappings->{$matchs[1]};
            foreach ($replace->debugInfo as $cacheLineNumber => $iii) {
                if ($line >= $cacheLineNumber) {
                    return $replace->fileName . ':' . $iii;
                }
            }
            return $replace->fileName . ':0';
        },
        $pot_contents
    );
    file_put_contents($po_file, $pot_contents);
}

poupdate($po_file);

$podir = realpath(__DIR__."/../po/")."/";
echo "PoDir: ${podir}\r\n";
foreach (glob("${podir}*.po") as $file) {
    exec("msgmerge --quiet --previous -U $file ${podir}account-manager.pot");
    echo "File: $file\r\n";
    poupdate($file);
}

