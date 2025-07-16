# git-at-home
Headless Git container for homelab

# deployment
```
wget https://raw.githubusercontent.com/NeptuneHub/git-at-home/refs/heads/main/deployment.yaml
```
before apply it remember to:
* change the path in the pv to match your correct local path, default is `/mnt/usb/git`
* change the node to match the correct node, default is `ubuntu3`

after the change you can apply:

```
kubectl apply -f deployment.yaml
```

# create the repo
If you want to create a repo called `audiomuse`, supposing that the ip of the loadbalancer is `192.168.3.17` you can just give this command:

```
ssh git@192.168.3.17 "mkdir -p /git/repos/audiomuse.git && git init --bare /git/repos/audiomuse.git"
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

to see the graph
```
git log --oneline --graph --all
```

# Push from Local to Remote server

Now let's say you have this local server on your K3S and you want time to time to push the content of master branch on the devel branch of your github repo. First step in your local server repo you need to add the reference to the remote server

```
git remote add github git@github.com:NeptuneHub/AudioMuse-AI.git
```

* **Important** for git we have setup the access by ssh key

Now you can check ths change with this command:
```
git remote -v
```

the output will be something like this:
```
github  git@github.com:NeptuneHub/AudioMuse-AI.git (fetch)
github  git@github.com:NeptuneHub/AudioMuse-AI.git (push)
origin  ssh://git@192.168.3.17/git/repos/audiomuse.git (fetch)
origin  ssh://git@192.168.3.17/git/repos/audiomuse.git (push)
```

Now you can push in this two way:
```
git push #push to the local server
git push github master:devel #push from local master to remote devel
```

if your local is empty and you want first to allign to remote, you can run this command:
```
git pull github devel
```

# useful command
If the ip is alredy in your known_host, you can remove it by this command:

```
ssh-keygen -R 192.168.3.17
```
