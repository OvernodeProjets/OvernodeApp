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

        // Clean up
        persistence.Clear();
        var empty = persistence.LoadCookies();
        Assert.AreEqual(0, empty.Count);
    }
}
