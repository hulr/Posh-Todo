#requires -version 3
$script:TodoPath = "$env:APPDATA\Posh-Todo"

function Add-Todo {
	<#
	.SYNOPSIS
		add a new todo list item

	.PARAMETER Todo
		text of the new todo list item

	.PARAMETER Category
        category of the new todo list item

    .PARAMETER Priority
        priority of the new todo list item
	#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [String] $Todo,
        [Parameter(Position=1, Mandatory=$false)]
        [String] $Category,
        [Parameter(Position=2, Mandatory=$false)]
        [Int] $Priority
    )
    begin {
        if (-not (Test-Path $TodoPath)) {
            New-Item -ItemType Directory -Path $TodoPath | Out-Null
        }
    }
    process {
        try {
            $Id = [int](Get-ChildItem -Directory -Path $TodoPath | Measure-Object | Select-Object -Property Count | Format-Table -HideTableHeaders | Out-String).Trim()
            New-Item -ItemType Directory -Path $TodoPath -Name $Id | Out-Null
            New-Item -ItemType File -Path "$TodoPath\$Id" -Name todo.txt -Value $Todo | Out-Null
            if ($Category) {
                New-Item -ItemType File -Path "$TodoPath\$Id" -Name category.txt -Value $Category | Out-Null
            }
            if ($Priority) {
                New-Item -ItemType File -Path "$TodoPath\$Id" -Name priority.txt -Value $Priority | Out-Null
            }
            Write-Output "Posh-Todo: new item created with id $Id"
        } catch {
            Write-Output $_.Exception.Message
        }
    }
    end {}
}

function Get-Todo {
	<#
	.SYNOPSIS
		get existing todo list items

	.PARAMETER Id
		get todo list item of specified id

	.PARAMETER Category
        get todo list items of specified category

    .PARAMETER Priority
        get todo list items of specified priority
	#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$false)]
        [Int] $Id,
        [Parameter(Position=1, Mandatory=$false)]
        [String] $Category,
        [Parameter(Position=2, Mandatory=$false)]
        [Int] $Priority
    )
    begin {
        $Entries = Get-ChildItem -Path $TodoPath -Directory -ErrorAction SilentlyContinue | Where-Object -Property Name -NotMatch "x"
        if ((-not (Test-Path $TodoPath)) -or ($Entries.Length -eq 0)) {
            Write-Output "Posh-Todo: nothing to show"
            break
        }
    }
    process {
        try {
            $TodoArray = @()
            foreach ($Directory in $Entries) {
                $PSObject = New-Object -TypeName PSObject
                $PSObject | Add-Member -MemberType NoteProperty -Name Id -Value $([int]$Directory.Name)
                $PSObject | Add-Member -MemberType NoteProperty -Name Priority -Value $(Get-Content "$TodoPath\$Directory\priority.txt" -Encoding utf8 -ErrorAction SilentlyContinue)
                $PSObject | Add-Member -MemberType NoteProperty -Name Category -Value $(Get-Content "$TodoPath\$Directory\category.txt" -Encoding utf8 -ErrorAction SilentlyContinue)
                $PSObject | Add-Member -MemberType NoteProperty -Name Todo -Value $(Get-Content "$TodoPath\$Directory\todo.txt" -Encoding utf8)
                $TodoArray += $PSObject
                Remove-Variable -Name PSObject
            }
            if ($Id) {
                Write-Output $TodoArray | Where-Object -Property Id -eq $Id
            } elseif ($Category) {
                if ($Priority) {
                    Write-Output $TodoArray | Where-Object -Property Category -eq $Category | Where-Object -Property Priority -eq $Priority | Sort-Object -Property Id
                } else {
                    Write-Output $TodoArray | Where-Object -Property Category -eq $Category | Sort-Object -Property Id
                }
            } elseif ($Priority) {
                Write-Output $TodoArray | Where-Object -Property Priority -eq $Priority | Sort-Object -Property Id
            } else {
                Write-Output $TodoArray | Sort-Object -Property Id
            }
        } catch {
            Write-Output $_.Exception.Message
        }
    }
    end {}
}

function Complete-Todo {
	<#
	.SYNOPSIS
		mark todo list item as completed

	.PARAMETER Id
		id of todo list item to complete
	#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [Int] $Id
    )
    begin {
        if (-not (Test-Path "$TodoPath\$Id"))  {
            Write-Output "Posh-Todo: no item with id $Id found"
            break
        }
    }
    process {
        try {
            Rename-Item -Path "$TodoPath\$Id" -NewName ([string]$Id + "x")
            Write-Output "Posh-Todo: item with id $Id completed"
        } catch {
            Write-Output $_.Exception.Message
        }
    }
    end {}
}

function Update-Todo {
	<#
	.SYNOPSIS
		update existing todo list item

	.PARAMETER Id
        id of todo list item to update

	.PARAMETER Todo
		new text of the existing todo list item

	.PARAMETER Category
        new category of the existing todo list item

    .PARAMETER Priority
        new priority of the existing todo list item
	#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [Int] $Id,
        [Parameter(Position=1, Mandatory=$false)]
        [String] $Todo,
        [Parameter(Position=2, Mandatory=$false)]
        [String] $Category,
        [Parameter(Position=3, Mandatory=$false)]
        [nullable[Int]] $Priority
    )
    begin {
        $PriorityString = [string]$Priority
        if (-not (Test-Path "$TodoPath\$Id"))  {
            Write-Output "Posh-Todo: no item with id $Id found"
            break
        } elseif (($Todo.Length -eq 0) -and ($Category.Length -eq 0) -and ($PriorityString.Length -eq 0)) {
            Write-Output "Posh-Todo: nothing to update"
            break
        }
    }
    process {
        try {
            if ($Todo.Length -gt 0) {
                Set-Content -Path "$TodoPath\$Id\todo.txt" -Value $Todo
            }
            if ($Category.Length -gt 0) {
                Set-Content -Path "$TodoPath\$Id\category.txt" -Value $Category
            }
            if ($PriorityString.Length -gt 0) {
                Set-Content -Path "$TodoPath\$Id\priority.txt" -Value $Priority
            }
            Write-Output "Posh-Todo: updated item with id $Id"
        } catch {
            Write-Output $_.Exception.Message
        }
    }
    end {}
}

function t {
	<#
	.SYNOPSIS
		shortcut command for all todo functions: add, list, remove, update todo list items
	#>
    switch ($args[0]) {
        add {Add-Todo -Todo $args[1] -Category $args[2] -Priority $args[3]}
        ls {Get-Todo -Id $args[1] -Category $args[2] -Priority $args[3]}
        rm {Complete-Todo -Id $args[1]}
        up {
            switch ($args[2]) {
                td {Update-Todo -Id $args[1] -Todo $args[3]}
                ct {Update-Todo -Id $args[1] -Category $args[3]}
                pr {Update-Todo -Id $args[1] -Priority $args[3]}
				default {Write-Output "usage: t up <id> [<args>]`r`n`r`nargs:`r`ntd [todo]`r`nct [category]`r`npr [priority]`r`n"}
            }
        }
		default {Write-Output "usage: t <command> [<args>]`r`n`r`ncommands:`r`nadd [todo] [category] [priority]`r`nls [id] [category] [priority]`r`nrm [id]`r`nup [id]`r`n"}
    }
}

Export-ModuleMember -Function *