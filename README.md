# git-at-home
Headless Git container for homelab

# deployment
```
wget https://raw.githubusercontent.com/NeptuneHub/git-at-home/refs/heads/main/deployment.yaml
kubectl apply -f deployment.yaml
```

# create the repo
If you want to create a repo called `audiomuse`, supposing that the ip of the loadbalancer is `192.168.3.17` you can just give this command:

```
ssh git@192.168.3.17 "mkdir -p /git/repos/my-project.git && git init --bare /git/repos/audiomuse.git"
```

you then need to enter the password that by default is `changeme`

# use the repo
The normal git command to test that everything work are this:
```
git clone ssh://git@192.168.3.17/git/repos/audiomuse.git
git config --global user.email "g.colangiuli@gmail.com"
git config --global user.name "neptunehub"
git add test.txt
git commit -m "Add test file"
git push
```

# useful command
If the ip is alredy in your known_host, you can remove it by this command:

```
ssh-keygen -R 192.168.3.17
```
