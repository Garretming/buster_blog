给 .gitignore 文件添加以下内容即可在向 Github 提交项目更改时，忽略掉该文件/文件夹：
// 给 .gitignore 添加以下内容
Ghost/
Buster/
如果自己有一个域名，并希望访客输入 username.github.io 时，自动跳转到个性化域名上去，可在项目根目录新建一个 CNAME 文件：
// 直接添加域名即可，不需要 http 或 https
// 例如我的 CNAME 是这样的

loyalsoldier.me
将项目提交到 Github。一两分钟后，访问 http://username.github.io 或 CNAME 文件中设置的个性域名，就可以访问自己的 Ghost 博客啦！

