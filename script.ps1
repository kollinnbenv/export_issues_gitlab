# Configurações
$gitLabApiUrl = "<link gitlab aqui>/api/v4"
$projectId = "id do projeto aqui"
$privateToken = "seu token aqui"

# Cabeçalho para autenticação na API do GitLab
$headers = @{
    "PRIVATE-TOKEN" = $privateToken
}

# URL base para obter as issues do projeto
$issuesUrl = "$gitLabApiUrl/projects/$projectId/issues"

# Lista para armazenar todas as issues, imagens e comentários
$allData = @()

# Criar o diretório para armazenar as imagens
$imageDirectory = "./image/"
if (-not (Test-Path -Path $imageDirectory -PathType Container)) {
    New-Item -Path $imageDirectory -ItemType Directory | Out-Null
}

# Loop para obter todas as páginas automaticamente
foreach ($page in 1..[int]::MaxValue) {
    # Adiciona o número da página à URL
    $pageUrl = "$gitLabApiUrl/projects/92/issues?page=$page&state=opened"

    # Obtém as issues da página atual
    $issues = Invoke-RestMethod -Uri $pageUrl -Headers $headers -Method Get

    # Sai do loop se não houver mais issues
    if ($issues.Count -eq 0) {
        break
    }

   # ...

# Itera sobre as issues
foreach ($issue in $issues) {
    # Obtem os comentários da issue
    $commentsUrl = "$gitLabApiUrl/projects/$projectId/issues/$($issue.Iid)/notes"
    $comments = Invoke-RestMethod -Uri $commentsUrl -Headers $headers -Method Get

    # Adiciona os comentários à lista geral de comentários
    $allComments = @()
    foreach ($comment in $comments) {
        # Verifica se o campo 'body' não é nulo ou vazio
        if (-not [string]::IsNullOrEmpty($comment.body)) {
            $allComments += $comment.body
        }
    }

    # Obtém a descrição da issue (ajuste conforme necessário)
    $description = if ($issue.PSObject.Properties['description']) { $issue.description } else { '' }

    # Constrói o objeto da issue com os comentários
    $issueObject = [PSCustomObject]@{
        Id          = $issue.Id
        Title       = $issue.Title
        Created_At  = $issue.Created_At
        Description = $description
        Comments    = $allComments
    }

    # Adiciona a issue com comentários à lista geral
    $allData += $issueObject

# ...
}
}
    
   
    
# Exporta todas as informações para arquivo JSON
$allData | ConvertTo-Json -Depth 10 |  ForEach-Object { "`n$_" } | ForEach-Object {
    $jsonString = $_ -replace '\\u([0-9a-fA-F]{4})', { [char]::ConvertFromUtf32([Convert]::ToInt32($matches[1], 16)) }
    [System.IO.File]::WriteAllText('./export_data.json', $jsonString, [System.Text.Encoding]::GetEncoding('Windows-1252'))
}
Write-Host "Todas as issues, imagens e comentários foram exportados com sucesso."

