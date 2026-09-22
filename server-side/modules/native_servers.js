const axios = require('axios');
const loadConfig = require('../handlers/config.js');
const settings = loadConfig('./config.toml');

const pteroClientApi = axios.create({
  baseURL: settings.pterodactyl.domain,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + settings.pterodactyl.client_key
  }
});

const HeliactylModule = {
  name: 'NativeServers',
  version: '1.0.0',
  api_level: 4,
  target_platform: '10.0.0',
  description: 'Provide live server status and resources for native macOS client',
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

  // GET /api/v5/servers/status - List user servers with realtime status and resource consumption
  app.get('/api/v5/servers/status', async (req, res) => {
    try {
      if (!authz.hasUserSession(req)) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      const sessionUser = authz.getSessionUser(req);
      const user = await cache.getOrSet(
        'ptero:user:' + sessionUser.id + ':servers',
        () => getPteroUser(sessionUser.id, db),
        15
      );

      if (!user || !user.attributes || !user.attributes.relationships || !user.attributes.relationships.servers) {
        return res.json([]);
      }

      const servers = user.attributes.relationships.servers.data || [];
      if (servers.length === 0) {
        return res.json([]);
      }

      const enriched = await Promise.all(
        servers.map(async (srv) => {
          const attr = srv.attributes || {};
          const identifier = attr.identifier || String(attr.id);
          const name = attr.name || 'Server';
          const limits = attr.limits || { memory: 0, cpu: 0, disk: 0 };
          const suspended = Boolean(attr.suspended);

          let state = suspended ? 'suspended' : 'offline';
          let memoryBytes = 0;
          let cpuPercent = 0;
          let diskBytes = 0;

          if (!suspended) {
            try {
              const resResp = await pteroClientApi.get('/api/client/servers/' + identifier + '/resources', {
                timeout: 3500
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
            state: state, // 'running', 'starting', 'stopping', 'offline', 'suspended'
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
