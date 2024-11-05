#Powershell script to convert Ashitacast to LuAshitacast equipment set
#Define file paths as variables Source XML - Destination LUA: Full path
#In FFXI whit luashitacast loaded : Create a new file first :  /lac newlua

# Define file paths as variables
$sourceFilePath = ""
$destinationFilePath = ""

# Read the raw XML content from the source file
$rawXmlContent = Get-Content -Path $sourceFilePath

# Parse the XML content
[xml]$xmlContent = $rawXmlContent

# Ensure the XML is parsed correctly
if ($xmlContent -eq $null) {
    Write-Host "Failed to parse XML content."
    exit
}

# Check if sets are present
if ($xmlContent.ashitacast.sets -eq $null) {
    Write-Host "No sets section found in the XML content."
    exit
} else {
    Write-Host "Sets section found."
}

# Function to convert XML elements to Lua table entries with capitalized slot names
function Convert-XmlToLua {
    param ($xmlElement)
    $entries = @()
    foreach ($set in $xmlElement.sets.set) {
        $setName = $set.name
        $entries += "    ['$setName'] = {"
        Write-Host "Importing set: $setName"  # Debug output
        foreach ($child in $set.ChildNodes) {
            if ($child.Name -ne 'baseset' -and $child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $itemName = $child.Name.Substring(0,1).ToUpper() + $child.Name.Substring(1).ToLower()
                $itemValue = $child.InnerText -replace "'", "\'"  # Escape single quotes for Lua
                $entries += "        $itemName = '$itemValue',"
            }
        }
        $entries += "    },"
    }
    return $entries -join "`n"
}

# Convert all sets
$luaEntriesString = Convert-XmlToLua -xmlElement $xmlContent.ashitacast

# Print all the sets and their items to the console
Write-Host "`n--- Imported Sets ---"
Write-Host $luaEntriesString
Write-Host "--- End of Sets ---`n"

# Read the destination Lua content
$luaContent = Get-Content -Path $destinationFilePath

# Find the index where `local sets = {` is defined
$setsIndex = ($luaContent -join "`n").IndexOf("local sets = {") + ("local sets = {").Length

# Insert the converted entries into the sets table
$luaContent = ($luaContent -join "`n").Insert($setsIndex, "`n$luaEntriesString`n")

# Write the updated Lua content back to the destination file
Set-Content -Path $destinationFilePath -Value ($luaContent -split "`n")

Write-Output "Conversion complete. Lua file saved to $destinationFilePath"
