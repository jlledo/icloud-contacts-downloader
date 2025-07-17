import os
from pyicloud import PyiCloudService

username = os.environ["ICLOUD_USERNAME"]
cookie_directory = os.getenv("COOKIE_DIRECTORY", "~/.pyicloud")

icloud = PyiCloudService(username, cookie_directory=cookie_directory)

print(icloud.contacts.all)
