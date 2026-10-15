# SSE 接收与消息打印

入口：系统设置 → 打印机设置后面的「SSE 设置」→ 二级页面。

## 连接

- SmartWe 使用当前激活设备的 machineCode；Panda 可以添加多个不同标识的订阅。默认关闭，保存后立即应用，重启恢复。
- 服务跟随 Riverpod ProviderScope 生命周期，离开有打印宿主的业务路由时断开；返回业务路由后重新连接。没有激活设备号时不连接。
- 订阅 GET `/web/subscribe/smartWe/{identify}` 或 `/web/subscribe/panda/{identify}`，默认使用当前 APP_ENV 对应的 apiProfileBase。`--dart-define=SSE_BASE_URL=https://your-sse-host` 可以覆盖推送服务器根地址，回调仍使用业务 API。
- 使用已有 http 依赖，不添加重复重连库。UTF-8、CR/LF、BOM、注释心跳、多行 data、id、retry 按 WHATWG SSE 规则解析；未结束的事件不提交游标。
- 连接超时 15 秒，流空闲超时 65 秒；一个重连入口，指数退避、抖动和有界 retry。主动断开会取消订阅、请求、心跳和重连定时器。HTTP 204 和明确的 4xx 拒绝停止自动重连，可以在页面重新连接。
- 不依赖移动系统在后台持续运行；系统挂起恢复后依靠心跳超时重连。后台长期运行须另做平台能力验证。

协议依据：[WHATWG Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html)。

## 打印合同

| 事件 | 内容与路由 |
| --- | --- |
| message / rePrint | 使用旧工程同一 JSON：uuid、order_sn_code、order_type、orderTime、remark、from_plate、payment_code、orderLinesMap。按 map 的键匹配打印机 type。 |
| print | 桌位单：line1、line2、description、qrCode，使用 11 号网络打印机，订阅须开启桌位打印。 |
| expiryPrint | 效期标签：name、saveMethod、expiredTimeStr、printTimeStr、operatorName，使用 10 号网络打印机，须设置标签模式和尺寸。 |
| heartbeat | 只刷新连接活性，不打印、不回调。 |

当前复用现有网络图片打印管线，小票沿用现有连续／单品模板，标签沿用现有标签模板（按数量展开、旋转、选项开关和纸张尺寸）。SmartWe／Panda 各自可开启中央汇总单，外带汇总到 11 号打印机。SSE 不触发本机顾客收据，以免与收银流程重复出单。

payment_Completed、item_cancel 不触发打印，也不向叫号系统推送。订单推送仅转发 message 的新订单 data，rePrint 仅补打、不向叫号系统推送，并且独立于打印配置和结果。参见 [订单推送](order_calling.md)。

先解析并验证所有路由和模板，再 POST `/web/sse/received/callback`，body 为 `{ "uuid": "..." }`。遵循旧合同，code=200 且 data 非空才提交打印。UUID 是业务去重键，SSE id 仅用于断线续接，两者不混用。回调不自动重试，避免请求结果不确定时重复抢占。

## 异常与记录

- 所有消息串行处理，同一网络地址和端口的发送串行，不同打印端点可独立发送。
- 配置保存在安全存储，打印记录按 UUID 单独写入 Hive 并 flush，避免把订单消息堆积进 Keychain。回调前持久化记录，发送前再次持久化；UUID 去重跨应用重启。保存最近 500 条记录，清理时仅淘汰已发送／服务端拒绝记录，未解决任务不会静默丢弃。页面显示最近 100 条。
- 配置或内容错误在回调前终止，记录为「配置或内容错误」。修正设置后在记录中点「重试」，重新验证后才回调后端。
- 回调超时、传输失败或应用在回调／发送期间中断，记录为「结果不确定」，不会自动重印。检查纸张输出后，从订单补打；效期／桌位单需要业务端重新发起新的 UUID。
- sent 表示图片已生成且传输返回成功，不表示纸张已实际打印。设备缺纸、卡纸、物理校准和二维码可扫性需要真机确认。
- 记录页可查看错误、已发送任务数和原始消息；日志不输出订阅完整 URL。

## 打印机设置修正

- 外部打印机可切换小票／标签模式；切换为标签且未设置尺寸时默认 300×225 像素。
- 标签保留现有尺寸并补充 60×60、30×60 选项；测试尺寸须与实际纸张、驱动和打印机校准一致。
- 图片打印现在传递并使用配置的端口，默认 9100；不再只保存端口却忽略它。
- 标签每次渲染仅传入目标打印机的商品，避免跨打印机混打。选项显示遵循同一打印机的 option 设置。

## 验证边界

自动测试覆盖协议分片、重连／关闭竞态、心跳超时、恢复游标、环境地址、路由验证、标签分流、回调异常、持久化去重、设置编辑与打印宿主生命周期。还需在目标设备上验证真实服务端推送、UUID 回调竞争、实际打印机端口、标签走纸、旋转、长商品名和二维码。
