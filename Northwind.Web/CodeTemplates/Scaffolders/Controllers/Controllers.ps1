[T4Scaffolding.Scaffolder(Description = "Enter a description of Generator here")][CmdletBinding()]
param(
	[parameter(Mandatory = $true, Position = 0)][string]$ContextTypeName,  
    [string]$Project,
	[string]$CodeLanguage,
	[string[]]$TemplateFolders,
	[switch]$Force = $false
)

$context = Get-ProjectType $ContextTypeName
$defaultNamespace = (Get-Project $Project).Properties.Item("DefaultNamespace").Value
$controllerNamespace = $defaultNamespace + ".Controllers"
$modelNamespace = $defaultNamespace + ".Models"
$webEventsNamespace = $defaultNamespace + ".WebEvents"
$pattern = "DbSet<([^>]+)>"

Add-ProjectItemViaTemplate (Join-Path Controllers BaseApiController) -Template BaseControllerTemplate `
	-Model @{ Namespace = $controllerNamespace;
				ContextTypeName = $ContextTypeName; } `
	-SuccessMessage "Added Controller output at {0}" `
	-TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force

$context.Members | ForEach {
	$typeName = $_.Type.AsFullName
	If ([System.Text.RegularExpressions.Regex]::IsMatch($typeName, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {	
		$memberName = $_.Name
		$match = [System.Text.RegularExpressions.Regex]::Match($typeName, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
		$entityTypeName = $match.Groups[1].Value
		$entityType = Get-ProjectType $entityTypeName
		$primaryKey = Get-PrimaryKey $entityTypeName
		$controllerTypeName = $memberName
		$className = $entityTypeName.Substring($entityTypeName.LastIndexOf('.') + 1)
		$entityNamespace = $entityTypeName.Substring(0, $entityTypeName.LastIndexOf('.'))
		$modelTypeName = $className + "Model"
		$controllerPath = (Join-Path Controllers ($memberName + "Controller")) + ".generated"
			
		#Write-Host Generating Model for $entityTypeName

		Add-ProjectItemViaTemplate $controllerPath -Template ControllerTemplate `
			-Model @{ Namespace = $controllerNamespace; 
						ModelNamespace = $modelNamespace;
						EntityNamespace = $entityNamespace;
						WebEventsNamespace = $webEventsNamespace;
						ClassName = $className;
						TypeName = $controllerTypeName; 
						ModelTypeName = $modelTypeName; 
						EntityType = $entityType; 
						PrimaryKey = $primaryKey; } `
			-SuccessMessage "Added Controller output at {0}" `
			-TemplateFolders $TemplateFolders -Project $Project -CodeLanguage $CodeLanguage -Force:$Force
	}
}