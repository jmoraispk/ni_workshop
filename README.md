# NI Workshop instructions

```bash
# Step 1 - build container
docker build -f Dockerfile -t ettus_workshop .

## Step 2 - start container
docker run -it --network host --device /dev/bus/usb:/dev/bus/usb -v "$PWD":/home ettus_workshop

## Step 3 - run workshop_setup.sh inside container
chmod +x setup_ettus_workshop.sh
./setup_ettus_workshop.sh

# Other Docker Commands (Recover or Clean up container)
docker ps -a
docker start -ai <container_name>   # start the container again, if it exited (keeps packages)
docker rm <container_name>
```
