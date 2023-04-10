cd $1
git init
git remote add origin http://localhost:3000/nephio/$2.git
git pull origin main
git checkout -b main
git add *
git commit -m "first commit"
git push -f http://nephio:$3@localhost:3000/nephio/$2.git
