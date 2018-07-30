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

  header('Content-Type: application/json');

  $array = [];
  foreach (dirStructure("json") as $key => $value) {
    foreach ($value as $data => $path) {
      sort($path);
      $array[$key][$data] = $path;
    }
  }

  echo json_encode($array, JSON_PRETTY_PRINT);
