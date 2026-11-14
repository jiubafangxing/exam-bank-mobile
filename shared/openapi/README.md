# shared/openapi（本地私有，不入库）

后端契约（OpenAPI）属于 **exam-bank 私有后端资产**，**禁止提交到本仓库**。

- 需要本地查阅时，自行把契约放到此目录，`.gitignore` 已忽略 `shared/openapi/*.yaml`；
- 本仓库的客户端代码只实现调用，不随仓库分发契约文档；
- 若需彻底不暴露 API 面，仓库应设为 **private**（公开客户端源码本身会体现请求路径）。
