# WiFi检测和sing-box服务管理脚本
# 作者: 系统管理员
# 日期: 2025年7月23日

# 定义需要监控的WiFi名称列表
$TargetWifiNames = @(
    "5.0"
)

# sing-box服务名称
$ServiceName = "sing-box"

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
            Write-Host "未检测到WiFi连接" -ForegroundColor Yellow
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
        Write-Host "正在启动服务 '$ServiceName'..." -ForegroundColor Yellow
        Start-Service -Name $ServiceName

        # 等待一会儿并检查服务状态
        Start-Sleep -Seconds 3
        $status = Get-ServiceStatus -ServiceName $ServiceName

        if ($status -eq "Running") {
            Write-Host "服务 '$ServiceName' 已成功启动" -ForegroundColor Green
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
        Write-Host "正在停止服务 '$ServiceName'..." -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force

        # 等待一会儿并检查服务状态
        Start-Sleep -Seconds 3
        $status = Get-ServiceStatus -ServiceName $ServiceName

        if ($status -eq "Stopped") {
            Write-Host "服务 '$ServiceName' 已成功停止" -ForegroundColor Green
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
Write-Host "========== WiFi检测和sing-box服务管理脚本 ==========" -ForegroundColor Cyan
Write-Host "开始检测WiFi连接状态..." -ForegroundColor White

# 获取当前WiFi名称
$currentWifi = Get-CurrentWifiName

if ($currentWifi) {
    Write-Host "当前连接的WiFi: $currentWifi" -ForegroundColor Green

    # 检查是否在目标WiFi列表中
    if ($TargetWifiNames -contains $currentWifi) {
        Write-Host "当前WiFi '$currentWifi' 在监控列表中" -ForegroundColor Green

        # 检查sing-box服务状态
        Write-Host "检查 '$ServiceName' 服务状态..." -ForegroundColor White
        $serviceStatus = Get-ServiceStatus -ServiceName $ServiceName

        if ($serviceStatus) {
            Write-Host "服务 '$ServiceName' 当前状态: $serviceStatus" -ForegroundColor Blue

            if ($serviceStatus -eq "Running") {
                Write-Host "服务 '$ServiceName' 正在运行中，准备停止..." -ForegroundColor Yellow
                $stopResult = Stop-ServiceSafely -ServiceName $ServiceName

                if ($stopResult) {
                    Write-Host "操作完成：服务已成功停止" -ForegroundColor Green
                }
                else {
                    Write-Host "操作失败：无法停止服务" -ForegroundColor Red
                }
            }
            elseif ($serviceStatus -eq "Stopped") {
                Write-Host "服务 '$ServiceName' 已经停止" -ForegroundColor Green
            }
            else {
                Write-Host "服务 '$ServiceName' 状态异常: $serviceStatus" -ForegroundColor Yellow
                Write-Host "尝试停止服务..." -ForegroundColor Yellow
                Stop-ServiceSafely -ServiceName $ServiceName
            }
        }
    }
    else {
        Write-Host "当前WiFi '$currentWifi' 不在监控列表中" -ForegroundColor Yellow
        Write-Host "监控的WiFi列表: $($TargetWifiNames -join ', ')" -ForegroundColor Gray
        
        # 检查sing-box服务状态
        Write-Host "检查 '$ServiceName' 服务状态..." -ForegroundColor White
        $serviceStatus = Get-ServiceStatus -ServiceName $ServiceName

        if ($serviceStatus) {
            Write-Host "服务 '$ServiceName' 当前状态: $serviceStatus" -ForegroundColor Blue

            if ($serviceStatus -eq "Stopped") {
                Write-Host "服务 '$ServiceName' 已停止，准备启动..." -ForegroundColor Yellow
                $startResult = Start-ServiceSafely -ServiceName $ServiceName

                if ($startResult) {
                    Write-Host "操作完成：服务已成功启动" -ForegroundColor Green
                }
                else {
                    Write-Host "操作失败：无法启动服务" -ForegroundColor Red
                }
            }
            elseif ($serviceStatus -eq "Running") {
                Write-Host "服务 '$ServiceName' 已经在运行中" -ForegroundColor Green
            }
            else {
                Write-Host "服务 '$ServiceName' 状态异常: $serviceStatus" -ForegroundColor Yellow
                Write-Host "尝试启动服务..." -ForegroundColor Yellow
                Start-ServiceSafely -ServiceName $ServiceName
            }
        }
    }
}
else {
    Write-Host "无法获取当前WiFi连接信息" -ForegroundColor Red
}

Write-Host "`n脚本执行完成" -ForegroundColor Cyan