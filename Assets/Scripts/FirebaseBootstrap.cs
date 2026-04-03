using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Firebase;
using UnityEngine;
using Firebase.RemoteConfig;
using Firebase.Analytics;

public class FirebaseBootstrap : MonoBehaviour
{
    [SerializeField]
    [Tooltip("Remote Config parameter names to read after fetch.")]
    private string[] remoteConfigKeys = Array.Empty<string>();
    
    async void Start()
    {
        Debug.Log("Firebase bootstrap started");
        var status = await Firebase.FirebaseApp.CheckAndFixDependenciesAsync();
        
        if (status != Firebase.DependencyStatus.Available)
        {
            Debug.LogError("Could not resolve all Firebase dependencies: " + status);
            return;
        }
        
        var app = FirebaseApp.DefaultInstance;
        Debug.Log($"Firebase App Ready {app.Name}");
        
        FirebaseAnalytics.LogEvent("unity_firebase_ping",
            new Parameter(FirebaseAnalytics.ParameterItemName, Application.version));
        Debug.Log("Firebase Analytics: logged event 'unity_firebase_ping'");
        
        Debug.Log("Firebase bootstrap Ended");

        Debug.Log("Firebase Remote Config Start");
        
        
        await InitRemoteConfigAsync();
        await FetchAndDisplayRemoteConfigAsync();
        
        Debug.Log("Firebase Remote Config End");
    }
    
    async Task InitRemoteConfigAsync()
    {
        var remoteConfig = FirebaseRemoteConfig.DefaultInstance;
        var defaults = new Dictionary<string, object>
        {
            { "welcome_message", "Hello" },
            { "max_level", "42" },
        };
        await remoteConfig.SetDefaultsAsync(defaults);
        Debug.Log("Remote Config initialized (defaults set).");
    }
    
    async Task FetchAndDisplayRemoteConfigAsync()
    {
        var remoteConfig = FirebaseRemoteConfig.DefaultInstance;
        await remoteConfig.FetchAsync(TimeSpan.Zero);
        if (remoteConfig.Info.LastFetchStatus == LastFetchStatus.Success)
            await remoteConfig.ActivateAsync();
        else
            Debug.LogWarning($"Remote Config fetch status: {remoteConfig.Info.LastFetchStatus}");
        foreach (var key in remoteConfigKeys)
        {
            if (string.IsNullOrWhiteSpace(key))
                continue;
            var v = remoteConfig.GetValue(key);
            Debug.Log(
                $"RemoteConfig '{key}': string={v.StringValue}");
        }
    }
}
