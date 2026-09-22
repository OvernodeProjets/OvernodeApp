const axios = require("axios");
const loadConfig = require("../handlers/config");
const settings = loadConfig("./config.toml");

let domain = settings.pterodactyl?.domain || "";
if (domain.endsWith("/")) {
  domain = domain.slice(0, -1);
}

const pteroApi = axios.create({
  baseURL: domain,
  timeout: 3500,
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": `Bearer ${settings.pterodactyl?.key || ""}`
  }
});

module.exports = async (userid, db) => {
  let dbUser = await db.user.findUnique({
    where: { id: userid },
    select: { id: true, email: true, username: true, pterodactylId: true }
  });
  let pteroId = dbUser?.pterodactylId;

  if (!pteroId && dbUser?.email) {
    try {
      const searchResp = await pteroApi.get(`/api/application/users?filter[email]=${encodeURIComponent(dbUser.email)}`);
      const foundUsers = searchResp.data?.data || [];
      if (foundUsers.length > 0 && foundUsers[0].attributes?.id) {
        pteroId = foundUsers[0].attributes.id;
        await db.user.update({
          where: { id: userid },
          data: { pterodactylId: pteroId }
        }).catch(() => {});
      }
    } catch (e) {}
  }

  if (!pteroId) {
    return {
      object: "user",
      attributes: {
        id: null,
        username: dbUser?.username || "User",
        email: dbUser?.email || "",
        relationships: {
          servers: {
            object: "list",
            data: []
          }
        }
      }
    };
  }

  try {
    const response = await pteroApi.get(`/api/application/users/${pteroId}?include=servers`);
    const data = response.data;
    if (data && data.attributes) {
      data.attributes.relationships = data.attributes.relationships || {};
      let srvList = data.attributes.relationships.servers?.data || [];
      
      if (srvList.length === 0) {
        try {
          const allSrvsResp = await pteroApi.get("/api/application/servers?per_page=100");
          const rawList = allSrvsResp.data?.data || [];
          const userServers = rawList.filter((s) => s.attributes?.user === pteroId);
          if (userServers.length > 0) {
            srvList = userServers;
          }
        } catch (srvErr) {}
      }
      
      data.attributes.relationships.servers = {
        object: "list",
        data: srvList
      };
    }
    return data;
  } catch (error) {
    if (error.response?.status === 404) {
      throw new Error("Pterodactyl account not found!");
    }
    if (error.response?.status === 401) {
      console.error(`[Pterodactyl] 401 Unauthorized - Check API key configuration`);
      throw new Error("Pterodactyl API authentication failed. Please check your API key configuration.");
    }
    throw error;
  }
};
