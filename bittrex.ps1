########################################
######  API BITTREX - Tybbow v0.1  #####
########################################

Function Get-StringHash($String,$HashName)
{
    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
    [Void]$StringBuilder.Append($_.ToString("x2"))}
    $string = $StringBuilder.ToString()
    return $string
}

function Get-HashBittrex($fullrul, $method, $query)
{
    $utf8enc = New-Object System.Text.UTF8Encoding

    $apikey = "<APIKEY>"
    $secret = "<SECRET>"

    $nonce = ([int](Get-Date -UFormat %s -Millisecond 0) * 1000) - 7200000

    if ($query -eq ""){$payload = $query} else {$payload = $query | ConvertTo-Json}


    $payload = $payload.ToString().replace("[", "").replace("]", "")

    $contentHash = Get-StringHash $payload "SHA512"
    #Write-Host $contentHash

    $pre_sign = [string]$nonce+$fullurl+$method+$contentHash

    $pre_signBytes = $utf8enc.GetBytes($pre_sign)

    ### Generate SHA 512 Hash
    $sha512 = New-Object System.Security.Cryptography.HMACSHA512
    $sha512.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $sha_result = $sha512.ComputeHash($pre_signBytes)

    $signature = [System.BitConverter]::ToString($sha_result) -replace "-"

    $headers = @{"Api-Key" = $apikey
                 "Api-Timestamp" = $nonce
                 "Api-Content-Hash" = $contentHash
                 "Api-Signature" = $signature
                 "Content-Type" = "application/json"
                 "Accept" = "application/json"
    }

    $optionsWeb = @{Headers = $headers; Payload = $payload}
    return $optionsWeb
}

function Query($method, $request, $uuid, $query)
{

    $url = "https://api.bittrex.com/v3/"
    $fullurl = $url+$request+$uuid

    $optionsWeb = Get-HashBittrex $fullurl $method $query

    if ($method -eq "GET" -or $method -eq "DELETE")
    {
        $responseFromServer = Invoke-WebRequest -uri $fullurl -Method $method -Headers $optionsWeb.Headers | ConvertFrom-Json
    }
    else
    {
        $responseFromServer = Invoke-WebRequest -uri $fullurl -Method $method -Headers $optionsWeb.Headers -Body $optionsWeb.Payload | ConvertFrom-Json
    }
    return $responseFromServer
}

$order = @()
$order += [PSCustomObject]@{
                "marketSymbol" = "ADA-USD"
                "direction" = "SELL"
                "type" = "LIMIT"
                "quantity" = "20"
                "limit" = "2.8"
                "timeInForce" = "GOOD_TIL_CANCELLED"
                "useAwards" = $False
}


$orderCond = @()
$orderCond += [PSCustomObject]@{
                "marketSymbol" = "ADA-USD"
                "operand" = "GTE"
                "triggerPrice" = "2.7999"
                "orderToCreate" = $order
 }


#$orders = Query "POST" "orders" "" $order
#$corders = Query "POST" "conditional-orders" $orderCond

Write-Host "### Balances ###"
$balances = Query "GET" "balances" "" ""
foreach($elem in $balances)
{
    Write-Host $elem
}
Write-Host ""


Write-Host "### Orders ###"
$openOrders = Query "GET" "orders/open" "" ""
foreach($elem in $openOrders)
{
    Write-Host $elem
    #$deleteOpen = Query "DELETE" "orders/" $elem.id ""
    #Write-Host "## Delete Open " $deleteOpen
}
Write-Host ""

Write-Host "### Conditionnal Orders ###"
$openOrdersCond = Query "GET" "conditional-orders/open" "" ""
foreach($elem in $openOrdersCond)
{
    Write-Host "open : "$elem
    #$deleteCOpen = Query "DELETE" ("conditional-orders/"+$elem.id) ""
}