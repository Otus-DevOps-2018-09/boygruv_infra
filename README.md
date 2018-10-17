# boygruv_infra
boygruv Infra repository

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


