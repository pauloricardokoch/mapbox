<?php
  function dirStructure($path)
  {
    $out   = [];
    $files = new FilesystemIterator($path);
    foreach ($files as $file)
    {
      if ($file->isDir())
        $out[$path][$file->getFilename()] = dirStructure($path . "/" . $file->getFilename());
      else
        $out[] = $file->getFilename();
    }

    return $out;
  }

  header("Access-Control-Allow-Origin: *");
  header("Access-Control-Allow-Methods: PUT, GET, POST");
  header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");
  header('Content-Type: application/json');

  $array = [];
  foreach (dirStructure("json") as $key => $value) {
    foreach ($value as $data => $path) {
      sort($path);
      $array[$key][$data] = $path;
    }
  }

  echo json_encode($array, JSON_PRETTY_PRINT);
