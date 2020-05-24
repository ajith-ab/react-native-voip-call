<?php

// Put your device token here (without spaces):
      $deviceToken = '1234567890123456789';
//


// Put your private key's passphrase here:
$passphrase = 'ProjectName';

// Put your alert message here:
$message = 'My first push notification!';



$ctx = stream_context_create();
stream_context_set_option($ctx, 'ssl', 'local_cert', 'PemFileName.pem'); // Replace with your pem file
stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

// Open a connection to the APNS server
$fp = stream_socket_client(
//  'ssl://gateway.push.apple.com:2195', $err,
    'ssl://gateway.sandbox.push.apple.com:2195', $err,
    $errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

if (!$fp)
    exit("Failed to connect: $err $errstr" . PHP_EOL);

echo 'Connected to APNS' . PHP_EOL;

// Create the payload body



$body = 
    [
       'aps' => 
           [
             'content-available'=> 1,
             'apns-push-type'=>'background',
             'apns-expiration' => 0
           ],
        'data' =>
            [
                'uuid'=> '825f4094-a674-4765-96a7-1ac512c02a71', //uuid must be uuid format otherwise it manually created
                'name' => 'RNVoip',
                'handle' => '123213782123', // phone number 
                'hasVideo' => true , // u are trying to audio call. please remove hasVideo key and value 
                'handleType' => 'generic' // options are `generic`, `number` and `email`
            ]
    
    ];
                  

// Encode the payload as JSON

$payload = json_encode($body);

// Build the binary notification
$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

// Send it to the server
$result = fwrite($fp, $msg, strlen($msg));

if (!$result)
    echo 'Message not delivered' . PHP_EOL;
else
    echo 'Message successfully delivered' . PHP_EOL;

// Close the connection to the server
fclose($fp);