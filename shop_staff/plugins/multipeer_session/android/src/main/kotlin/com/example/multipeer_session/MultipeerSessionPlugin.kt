package com.example.multipeer_session

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MultipeerSessionPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var events: EventChannel.EventSink? = null
    private var context: Context? = null
    private var connectionsClient: ConnectionsClient? = null
    private val handler = Handler(Looper.getMainLooper())
    private val connectedEndpoints = mutableSetOf<String>()
    private val endpointNames = mutableMapOf<String, String>()
    private val strategy = Strategy.P2P_POINT_TO_POINT
    private var serviceName: String = "multipeer-session"
    private var role: String = "unknown"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "multipeer_session/methods")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multipeer_session/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val args = call.arguments as? Map<*, *>
                val roleArg = args?.get("role") as? String
                val serviceArg = args?.get("serviceName") as? String
                if (roleArg == null || serviceArg == null) {
                    result.error("bad_args", "Missing role/serviceName", null)
                    return
                }
                role = roleArg
                serviceName = serviceArg.take(15).lowercase()
                startSession()
                result.success(null)
            }
            "stop" -> {
                stopSession()
                result.success(null)
            }
            "send" -> {
                val args = call.arguments as? Map<*, *>
                val data = args?.get("data") as? String
                val endpoints = connectedEndpoints.toList()
                if (data == null || endpoints.isEmpty() || connectionsClient == null) {
                    result.error("send_fail", "No connection or data", null)
                    return
                }
                val payload = Payload.fromBytes(data.toByteArray(Charsets.UTF_8))
                connectionsClient?.sendPayload(endpoints, payload)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopSession()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    private fun startSession() {
        stopSession()
        val ctx = context ?: return
        connectionsClient = Nearby.getConnectionsClient(ctx)
        val advertisingOptions = AdvertisingOptions.Builder().setStrategy(strategy).build()
        val discoveryOptions = DiscoveryOptions.Builder().setStrategy(strategy).build()

        connectionsClient?.startAdvertising(localEndpointName(ctx), serviceName, connectionLifecycleCallback, advertisingOptions)
            ?.addOnFailureListener { emit(mapOf("type" to "error", "message" to "adv_error: ${it.message}")) }

        connectionsClient?.startDiscovery(serviceName, endpointDiscoveryCallback, discoveryOptions)
            ?.addOnFailureListener { emit(mapOf("type" to "error", "message" to "browse_error: ${it.message}")) }
    }

    private fun stopSession() {
        connectionsClient?.stopAllEndpoints()
        connectionsClient?.stopAdvertising()
        connectionsClient?.stopDiscovery()
        connectedEndpoints.clear()
        endpointNames.clear()
        connectionsClient = null
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            endpointNames[endpointId] = info.endpointName
            connectionsClient?.requestConnection(localEndpointName(context), endpointId, connectionLifecycleCallback)
        }

        override fun onEndpointLost(endpointId: String) {
            endpointNames.remove(endpointId)
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            endpointNames[endpointId] = connectionInfo.endpointName
            connectionsClient?.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) {
            when (resolution.status.statusCode) {
                ConnectionsStatusCodes.STATUS_OK -> {
                    connectedEndpoints.add(endpointId)
                    emit(
                        mapOf(
                            "type" to "connected",
                            "peerName" to (endpointNames[endpointId] ?: "peer")
                        )
                    )
                }
                ConnectionsStatusCodes.STATUS_CONNECTION_REJECTED -> emit(
                    mapOf("type" to "error", "message" to "connection_rejected")
                )
                else -> emit(mapOf("type" to "error", "message" to "connection_failed"))
            }
        }

        override fun onDisconnected(endpointId: String) {
            connectedEndpoints.remove(endpointId)
            emit(mapOf("type" to "disconnected", "peerName" to (endpointNames[endpointId] ?: "peer")))
            endpointNames.remove(endpointId)
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            val bytes = payload.asBytes() ?: return
            val data = String(bytes, Charsets.UTF_8)
            emit(
                mapOf(
                    "type" to "message",
                    "data" to data,
                    "peerName" to (endpointNames[endpointId] ?: "peer")
                )
            )
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            if (update.status == PayloadTransferUpdate.Status.FAILURE) {
                emit(mapOf("type" to "error", "message" to "payload_failed"))
            }
        }
    }

    private fun emit(map: Map<String, Any?>) {
        handler.post { events?.success(map) }
    }

    private fun localEndpointName(ctx: Context?): String {
        if (ctx == null) return "peer-${role}"
        val model = Build.MODEL?.takeIf { it.isNotBlank() } ?: "Android"
        return "$model-${role}"
    }
}
