# boygruv_infra
boygruv Infra repository

## Homework-05

Установка Packer:
```
$ wget https://releases.hashicorp.com/packer/1.3.1/packer_1.3.1_linux_amd64.zip 
$ unzip packer_1.3.1_linux_amd64.zip
$ mv packer /usr/local/bin/x 
$ packer -v 
```
Создаём АDC (Application Default Credentials): 
```
$ gcloud auth application-default login

```

Создаем шаблон для packer: ubuntu16.json
```
{
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "infra-219820",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "ubuntu-1604-lts",
            "zone": "europe-west1-b",
            "ssh_username": "eav",
            "machine_type": "f1-micro"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}

```

Проверка валидности шаблона packer:
```
$ packer validate ./ubuntu16.json 
```

Сборка образа
```
$ packer build ubuntu16.json
```

На основе собранного образа создаем виртуалку и устанавливаем на нее puma-server
```
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install  
$ puma -d 

```

Добавим файл с пользовательскими переменными variables.json
Запуск сборки с файлом переменных
```
$ packer build -var-file=variables.json ubuntu16.json

```

Запуск виртуальной машины из консоли
```
gcloud compute instances create reddit-app\
  --boot-disk-size=11GB \
  --image-family=reddit-full \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure

```


****************************************************************************

## Homework-04

Создание инстанта из консоли (вариант 1: стартап скритп из локального файла)
```sh
$ gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup-script.sh
```

Создание инстанта из консоли (вариант 2: стартап скритп из бакета)
```sh
$ gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata=startup-script-url='gs://eav-otus/install.sh'
```
Сздание правила **firewall** из консоли
```sh
gcloud compute firewall-rules create default-puma-server --allow tcp:9292 \
  --target-tags=puma-server --source-ranges="0.0.0.0/0" \
  --description="Allow incoming traffic on Puma server"
```

Адрес сервера
----------------------
testapp_IP = 35.205.205.59
testapp_port = 9292 

****************************************************************************

## Homework-03

Подключение к **someinternalhost** через **bastion-host** в одну строку:

```sh
$ ssh -i ~/.ssh/ermolaev-gcp -A -t ermolaev-gcp@35.241.213.113 ssh 10.132.0.3
```

Вариант подключения к **someinternalhost** по алиасу:

```
Добавим в файл ~/.ssh/config алиас для подключения:
----------------------
Host someinternalhost
   HostName 10.132.0.3
   IdentityFile /root/.ssh/ermolaev-gcp
   user ermolaev-gcp
   ProxyCommand ssh -t ermolaev-gcp@35.241.213.113 nc %h %p
```
Теперь возможно подключение по алиасу **someinternalhost**
```sh
$ ssh someinternalhost
```

Подключение к **someinternalhost** через **OpenVPN**:
```sh
Устанавливаем клиента OpenVPN
----------------------
$ apt-get install openvpn

Копируем файл конфигурации: 
----------------------
cp /etc/openvpn/nato_test_natosrv.ovpn /etc/openvpn/client.conf

Устанавливаем соединение с сервером VPN
----------------------
$ openvpn /etc/openvpn/client.conf

Вводим логин и пароль установленный при заведении пользователя в дашбоард Pritunl

----------------------
Вариант с автоматическим подключением к серверу VPN
----------------------
В файле конфигурации /etc/openvpn/client.conf прописываем файл с логином и паролем для установки соединения
  auth-user-pass .secrets

Создаем файл с логином и паролем для подключения
----------------------
$ cat <<EOF> /etc/openvpn/.secrets
<username>
<password>
EOF

Перезапускаем сервис
----------------------
$ systemctl restart openvpn

Проверяем доступность сервера someinternalhost
$ ping 10.132.0.3

```

Адреса серверов
----------------------
bastion_IP = 35.241.213.113
someinternalhost_IP = 10.132.0.3


