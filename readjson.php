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
  echo json_encode(dirStructure("json"), JSON_PRETTY_PRINT);
