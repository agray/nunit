# the default version under development, update after a release
$version = '3.1.0'
$modifier = '-ci'

function isVersion($s){
    $v = New-Object Version
    [Version]::TryParse($s, [ref]$v)
}

# append the AppVeyor build number as the pre-release version
if ($env:appveyor){
	# if there is a tag, it provides both version and modifier
    if ($env:appveyor_repo_tag -eq 'true'){
        $tag = $env:appveyor_repo_tag_name
        $i = $tag.IndexOf('-')
        if($i -gt 0)
        {
            $version = $tag.Substring(0, $i)
            $modifier = $tag.Substring($i)
        } else {
            $version = $tag
            $modifier = ''
        }
    } else {
		# force build number to four digits for correct ordering
		$build_number = [int]::Parse($env:appveyor_build_number).ToString('0000');
		$modifier = $modifier + '-' + $build_number;

		# add branch if not master
		$branch = $env:appveyor_repo_branch;
		if($branch -ne 'master')
		{
			$modifier = $modifier + '-' + $branch;
		}

		$pr_number = $env:appveyor_pull_request_number;
		if($pr_number -ne '')
		{
			$modifier = $modifier + '-pr' + $pr_number;
		}
	}

    if(-not(isVersion($version)))
    {
        Write-Error "error parsing version '$version' in tag '$tag'"
        exit
    }
    Update-AppveyorBuild -Version "$version$modifier"
}

./build.cmd NUnit.proj /t:BuildAll /p:Configuration=Release /p:PackageVersion="$version" /p:PackageModifier="$modifier" /v:m
./build.cmd NUnit.proj /t:TestAll /p:Configuration=Release /p:PackageVersion="$version" /p:PackageModifier="$modifier" /v:m
./build.cmd NUnit.proj /t:"Package;PackageSL" /p:Configuration=Release /p:PackageVersion="$version" /p:PackageModifier="$modifier" /v:m
