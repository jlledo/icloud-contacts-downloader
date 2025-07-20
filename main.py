import os
from pyicloud import PyiCloudService

def main():
    username = os.environ["ICLOUD_USERNAME"]
    cookie_directory = os.getenv("COOKIE_DIRECTORY", "~/.pyicloud")
    
    icloud = PyiCloudService(username, cookie_directory=cookie_directory)
    
    print(icloud.contacts.all)

if __name__ == "__main__":
    main()