# WiFi检测和sing-box服务管理脚本
# 作者: 系统管理员
# 日期: 2025年7月23日

# 定义需要监控的WiFi名称列表
$TargetWifiNames = @(
    "5.0"
)

# sing-box服务名称
$ServiceName = "sing-box"

# 休眠间隔（秒）
$CheckInterval = 10

# 函数：获取当前连接的WiFi名称
function Get-CurrentWifiName {
    try {
        # 使用netsh命令获取当前连接的WiFi信息
        $wifiInfo = netsh wlan show interfaces | Select-String "SSID" | Where-Object { $_ -notmatch "BSSID" }

        if ($wifiInfo) {
            # 提取SSID名称
            $ssid = ($wifiInfo -split ":")[1].Trim()
            return $ssid
        }
        else {
            return $null
        }
    }
    catch {
        Write-Host "获取WiFi信息时出错: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：检查服务状态
function Get-ServiceStatus {
    param (
        [string]$ServiceName
    )

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            return $service.Status
        }
        else {
            Write-Host "服务 '$ServiceName' 不存在" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "检查服务状态时出错: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 函数：启动服务
function Start-ServiceSafely {
    param (
        [string]$ServiceName
    )

    try {
        Start-Service -Name $ServiceName

        # 等待一会儿并检查服务状态
        Start-Sleep -Seconds 3
        $status = Get-ServiceStatus -ServiceName $ServiceName

        if ($status -eq "Running") {
            return $true
        }
        else {
            Write-Host "服务 '$ServiceName' 启动失败，当前状态: $status" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "启动服务时出错: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 函数：停止服务
function Stop-ServiceSafely {
    param (
        [string]$ServiceName
    )

    try {
        Stop-Service -Name $ServiceName -Force

        # 等待一会儿并检查服务状态
        Start-Sleep -Seconds 3
        $status = Get-ServiceStatus -ServiceName $ServiceName

        if ($status -eq "Stopped") {
            return $true
        }
        else {
            Write-Host "服务 '$ServiceName' 停止失败，当前状态: $status" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "停止服务时出错: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 主程序逻辑

function Main{

    while($true){
        # 获取当前WiFi名称
        $currentWifi = Get-CurrentWifiName

        if ($currentWifi) {
            Write-Host "当前连接的WiFi: $currentWifi" -ForegroundColor Green

            # 检查是否在目标WiFi列表中
            if ($TargetWifiNames -contains $currentWifi) {
                # 检查sing-box服务状态
                $serviceStatus = Get-ServiceStatus -ServiceName $ServiceName

                if ($serviceStatus) {
                    if ($serviceStatus -eq "Running") {
                        Write-Host "服务 '$ServiceName' 正在运行中，准备停止..." -ForegroundColor Yellow
                        $stopResult = Stop-ServiceSafely -ServiceName $ServiceName

                        if (!$stopResult) {
                            Write-Host "操作失败：无法停止服务" -ForegroundColor Red
                        }
                    }
                }
            }
            else {
                # 检查sing-box服务状态
                $serviceStatus = Get-ServiceStatus -ServiceName $ServiceName

                if ($serviceStatus) {

                    if ($serviceStatus -eq "Stopped") {
                        $startResult = Start-ServiceSafely -ServiceName $ServiceName

                        if (!$startResult) {
                            Write-Host "操作失败：无法启动服务" -ForegroundColor Red
                        }
                    }
                }
            }
        }
        else {
            Write-Host "无法获取当前WiFi连接信息" -ForegroundColor Red
        }

        Start-Sleep $CheckInterval
    }
}

Main