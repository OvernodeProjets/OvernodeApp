using System;
using System.Collections.Generic;
using System.Net;
using Overnode.App.Services;

namespace Overnode.Tests;

public class SessionPersistenceTests
{
    public void Test_DPAPI_Save_And_Load_Cookies()
    {
        var persistence = SessionPersistence.Instance;
        var existingRealCookies = persistence.LoadCookies();

        try
        {
            persistence.Clear();

            var testCookies = new List<Cookie>
            {
                new("connect.sid", "s%3Atestsessionid12345.signature", "/", "console.overnode.fr")
                {
                    Secure = true,
                    HttpOnly = true,
                    Expires = DateTime.UtcNow.AddDays(7)
                }
            };

            // Act: Save encrypted via DPAPI
            persistence.SaveCookies(testCookies);

            // Act: Decrypt via DPAPI
            var loaded = persistence.LoadCookies();

            // Assert
            Assert.IsNotNull(loaded);
            Assert.IsTrue(loaded.Count > 0);
            var sidCookie = loaded.Find(c => c.Name == "connect.sid");
            Assert.IsNotNull(sidCookie);
            Assert.AreEqual("s%3Atestsessionid12345.signature", sidCookie.Value);
            Assert.IsTrue(sidCookie.Secure);
            Assert.IsTrue(sidCookie.HttpOnly);
        }
        finally
        {
            persistence.Clear();
            if (existingRealCookies != null && existingRealCookies.Count > 0)
            {
                persistence.SaveCookies(existingRealCookies);
            }
        }
    }

    public void Test_CookieContainer_Domains()
    {
        var baseUri = new Uri("https://console.overnode.fr");
        var container = new CookieContainer();

        var c1 = new Cookie("c1", "v1", "/", "overnode.fr");
        container.Add(baseUri, c1);

        var c2 = new Cookie("c2", "v2", "/", ".overnode.fr");
        container.Add(baseUri, c2);

        var c3 = new Cookie("c3", "v3", "/", "console.overnode.fr");
        container.Add(baseUri, c3);

        var retrieved = container.GetCookies(baseUri);
        Assert.IsTrue(retrieved.Count >= 3);
    }
}
