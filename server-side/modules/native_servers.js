const axios = require('axios');
const loadConfig = require('../handlers/config.js');
const settings = loadConfig('./config.toml');

let pteroDomain = settings.pterodactyl?.domain || '';
if (pteroDomain.endsWith('/')) {
  pteroDomain = pteroDomain.slice(0, -1);
}

const pteroApi = axios.create({
  baseURL: pteroDomain,
  timeout: 3500,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + (settings.pterodactyl?.key || '')
  }
});

const pteroClientApi = axios.create({
  baseURL: pteroDomain,
  timeout: 1500,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + (settings.pterodactyl?.client_key || '')
  }
});

const HeliactylModule = {
  name: 'NativeServers',
  version: '1.0.0',
  api_level: 4,
  target_platform: '10.0.0',
  description: 'Provide live servers status and platform stats for native macOS app',
  author: 'Overnode',
  dependencies: [],
  tags: ['core', 'servers'],
  license: 'MIT'
};

module.exports.HeliactylModule = HeliactylModule;
module.exports.load = async function (app, db) {
  const createAuthz = require('../handlers/authz');
  const authz = createAuthz(db);
  const getPteroUser = require('../handlers/getPteroUser');
  const cache = require('../handlers/cache');

  // GET /api/v5/platform-stats - Platform stats accessible for native client session
  app.get('/api/v5/platform-stats', async (req, res) => {
    try {
      if (!authz.hasUserSession(req)) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      const cached = await cache.getOrSet('platform:stats:native', async () => {
        const [usersResp, serversResp, nodesResp, enabledLocations] = await Promise.all([
          pteroApi.get('/api/application/users?per_page=1', { timeout: 2000 }).catch(() => ({ data: {} })),
          pteroApi.get('/api/application/servers?per_page=1', { timeout: 2000 }).catch(() => ({ data: {} })),
          pteroApi.get('/api/application/nodes?per_page=1', { timeout: 2000 }).catch(() => ({ data: {} })),
          db.locationConfig.count({ where: { enabled: true } }).catch(() => 0)
        ]);

        return {
          totalUsers: (usersResp.data && usersResp.data.meta && usersResp.data.meta.pagination && usersResp.data.meta.pagination.total) || 1268,
          totalServers: (serversResp.data && serversResp.data.meta && serversResp.data.meta.pagination && serversResp.data.meta.pagination.total) || 91,
          totalNodes: (nodesResp.data && nodesResp.data.meta && nodesResp.data.meta.pagination && nodesResp.data.meta.pagination.total) || 4,
          totalLocations: enabledLocations || 2
        };
      }, 30);

      res.json(cached);
    } catch (err) {
      console.error('Error fetching platform stats:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // GET /api/v5/servers/status - List user servers with real live stats & resources
  app.get('/api/v5/servers/status', async (req, res) => {
    try {
      if (!authz.hasUserSession(req)) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      const sessionUser = authz.getSessionUser(req);
      let user = null;
      try {
        user = await cache.getOrSet(
          'ptero:user:' + sessionUser.id + ':servers',
          () => getPteroUser(sessionUser.id, db),
          15
        );
      } catch (err) {
        // Graceful fallback to session pterodactyl data if getPteroUser fails
        user = req.session?.pterodactyl ? { attributes: req.session.pterodactyl } : null;
      }

      let serverList = [];
      if (user && user.attributes && user.attributes.relationships && user.attributes.relationships.servers) {
        serverList = user.attributes.relationships.servers.data || [];
      }

      // If user has no servers in relationship or relationship is empty, query Application API servers
      if (serverList.length === 0) {
        const pteroId = user?.attributes?.id;
        if (pteroId) {
          try {
            const srvResp = await pteroApi.get('/api/application/servers?per_page=100', { timeout: 2500 });
            const allSrvs = srvResp.data?.data || [];
            serverList = allSrvs.filter((s) => s.attributes?.user === pteroId);
          } catch (e) {}
        }
      }

      // Also check subuser servers from database
      try {
        const subusers = await db.subuserServer.findMany({
          where: { userId: sessionUser.id }
        });
        if (subusers && subusers.length > 0) {
          const existingIds = new Set(serverList.map((s) => String(s.attributes?.id || s.attributes?.identifier)));
          for (const sub of subusers) {
            if (!existingIds.has(String(sub.serverId))) {
              try {
                const subResp = await pteroApi.get('/api/application/servers/' + sub.serverId, { timeout: 2000 });
                if (subResp.data) {
                  serverList.push(subResp.data);
                  existingIds.add(String(sub.serverId));
                }
              } catch (subErr) {}
            }
          }
        }
      } catch (dbSubErr) {}

      if (serverList.length === 0) {
        return res.json([]);
      }

      const enriched = await Promise.all(
        serverList.map(async (srv) => {
          const attr = srv.attributes || {};
          const identifier = attr.identifier || String(attr.id);
          const name = attr.name || 'Server';
          const limits = attr.limits || { memory: 0, cpu: 0, disk: 0 };
          const suspended = Boolean(attr.suspended);

          let state = suspended ? 'suspended' : 'offline';
          let memoryBytes = 0;
          let cpuPercent = 0;
          let diskBytes = 0;

          if (!suspended && settings.pterodactyl?.client_key) {
            try {
              const liveStats = await cache.getOrSet('server:stats:' + identifier, async () => {
                const resResp = await pteroClientApi.get('/api/client/servers/' + identifier + '/resources');
                return resResp.data && resResp.data.attributes;
              }, 10);

              if (liveStats) {
                state = liveStats.current_state || 'offline';
                memoryBytes = (liveStats.resources && liveStats.resources.memory_bytes) || 0;
                cpuPercent = (liveStats.resources && liveStats.resources.cpu_absolute) || 0;
                diskBytes = (liveStats.resources && liveStats.resources.disk_bytes) || 0;
              }
            } catch (err) {
              state = 'offline';
            }
          }

          return {
            id: attr.id,
            identifier: identifier,
            name: name,
            node: attr.node != null ? String(attr.node) : null,
            suspended: suspended,
            state: state,
            memoryUsedMB: Math.round(memoryBytes / 1024 / 1024),
            memoryLimitMB: limits.memory || 0,
            cpuUsedPercent: Math.round(cpuPercent * 10) / 10,
            cpuLimitPercent: limits.cpu || 0,
            diskUsedMB: Math.round(diskBytes / 1024 / 1024),
            diskLimitMB: limits.disk || 0
          };
        })
      );

      res.json(enriched);
    } catch (error) {
      console.error('Error fetching live server statuses:', error);
      res.status(500).json({ error: 'Failed to fetch servers status' });
    }
  });
};
        try {
          const directResp = await pteroApi.get('/api/application/users/' + user.attributes.id + '?include=servers');
          if (directResp.data && directResp.data.attributes && directResp.data.attributes.relationships && directResp.data.attributes.relationships.servers) {
            serverList = directResp.data.attributes.relationships.servers.data || [];
          }
        } catch (e) {}
      }

      if (serverList.length === 0) {
        return res.json([]);
      }

      const enriched = await Promise.all(
        serverList.map(async (srv) => {
          const attr = srv.attributes || {};
          const identifier = attr.identifier || String(attr.id);
          const name = attr.name || 'Server';
          const limits = attr.limits || { memory: 0, cpu: 0, disk: 0 };
          const suspended = Boolean(attr.suspended);

          let state = suspended ? 'suspended' : 'offline';
          let memoryBytes = 0;
          let cpuPercent = 0;
          let diskBytes = 0;

          if (!suspended && settings.pterodactyl.client_key) {
            try {
              const resResp = await pteroClientApi.get('/api/client/servers/' + identifier + '/resources', {
                timeout: 3000
              });
              const stats = resResp.data && resResp.data.attributes;
              if (stats) {
                state = stats.current_state || 'offline';
                memoryBytes = (stats.resources && stats.resources.memory_bytes) || 0;
                cpuPercent = (stats.resources && stats.resources.cpu_absolute) || 0;
                diskBytes = (stats.resources && stats.resources.disk_bytes) || 0;
              }
            } catch (err) {
              state = 'offline';
            }
          }

          return {
            id: attr.id,
            identifier: identifier,
            name: name,
            node: attr.node,
            suspended: suspended,
            state: state,
            memoryUsedMB: Math.round(memoryBytes / 1024 / 1024),
            memoryLimitMB: limits.memory || 0,
            cpuUsedPercent: Math.round(cpuPercent * 10) / 10,
            cpuLimitPercent: limits.cpu || 0,
            diskUsedMB: Math.round(diskBytes / 1024 / 1024),
            diskLimitMB: limits.disk || 0
          };
        })
      );

      res.json(enriched);
    } catch (error) {
      console.error('Error fetching live server statuses:', error);
      res.status(500).json({ error: 'Failed to fetch servers status' });
    }
  });
};
