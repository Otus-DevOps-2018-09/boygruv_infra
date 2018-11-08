# boygruv_infra

## Homework-10

#### Ansible роли
- Создали отдельные роли для APP и DB

Инициализация новой роли (шаблона)
```sh
$ ansible-galaxy init app
```
#### Окружения
- Создали отдельные окружения: prod и stage
- Настройки окружений разместили в: `ansible/environments`
- Создали отдельные inventory для каждого окружения
- В ansible.cfg определили окружение по умолчанию (путь до inventory)
- Определили переменные для групп хостов (каталоги group_vars для каждого окружения)

Запуск деплоя для окружения:
```sh
$ ansible-playbook -i environments/prod/inventory playbooks/site.yml
```

#### Работа с Community-ролями
Внешние роли пописываем в файле requirements.yml для каждого окружения
```sh
 - src: jdauphant.nginx
   version: v2.21.1
```
Установка роли
```sh
$  ansible-galaxy install -r environments/stage/requirements.yml
```

#### Работа с Ansible Vault
- Путь к файлу с ключем прописываем в ansible.cfg
```sh
 [defaults]
 ...
 vault_password_file = vault.key
 ```

>Обязательно добавить в .gitignore файл vault.key.
А еще лучше - хранить его out-of-tree, аналогично ключам SSH (например, в папке ~/.ansible/vault.key)

Шифрация файла:
```sh
 $ ansible-vault encrypt environments/prod/credentials.yml
```
Расшифровка файла:
```sh
$ ansible-vault decrypt <file>
```
Редактирование файла:
```sh
$ ansible-vault edit <file>
```
#### Dynamic inventory
- Для динамической инвентори использую gce.py
- Для динамического инвентори добавил файлы: gce.py, gce.ini и secret.py в каталоги окружений
- Подправил плейбуки для доступа к хостам по тэгам: tag_reddit-app и tag_reddit-db
- Добавил в каталоги с групповами переменными файлы tag_reddit-app и tag_reddit-db с описанием переменных для тэгов

Запуск плейбука с динамическим инвентори (плейбуки запускаем из каталога: ansible):
```sh
$ ansible-playbook -i environments/stage/gce.py playbooks/site.yml
```



************************************
## Homework-09

#### Шаблоны конфигурационных файлов
Создали шаблон конфигурационного файла для MongoDB, определили переменные для заполнения конфига
```sh
--- 
- name: Configure hosts & deploy application 
  hosts: all 
  vars: 
    mongo_bind_ip: 0.0.0.0 
tasks: 
    - name: Change mongo config file 
      become: true 
      template: 
        src: templates/mongod.conf.j2 
        dest: /etc/mongod.conf 
        mode: 0644 
      tags: db-tag 
```
Запуск плейбука по определенной группе хостов
```sh
$ ansible-playbook reddit_app.yml --check --limit db
```

#### Handlers
Хендлеры срабатывают при наличии изменений в таске.
```sh
  handlers: 
  - name: restart mongod 
    become: true 
    service: name=mongod state=restarted
```
#### Плейбуки
- Разнесли плейбуки отдельно для APP, DB и DEPLOY
- Создали общий плейбук и импортировали в него плейбуки для каждого этапа

#### Dynamic inventory
- Для динамического инвенторя я выбрал gce.py, т.к. terraform-inventory имеет ограничения на использования удаленного бекэнда.
- Добавил ссылку на gce.py в ansible.cfg
- В плейбуках определил запуск на нужном хосте черег тэги

#### Провижинг в образах
- Пересоздал образа пакера reddit-app-base и  reddit-app-db с использованием провижинга через ansible


********************************
## Homework-08

#### Знакомстао с Ansible
Установка ansible (для работы требуется python >= 2.7)
```sh
$ apt-get install ansible

# Альтернативный вариант
$ pip install  ansible>=2.4

$ ansible --version
```
#### Inventory file
```sh
# Привер инвентори файла
appserver ansible_host=35.195.186.154 ansible_user=appuser \
    ansible_private_key_file=~/.ssh/appuser
```
YAML inventory
```sh
app:
  hosts:
    appserver:
      ansible_host: 104.155.0.53

db:
  hosts:
    dbserver:
      ansible_host: 35.233.45.195

```


Запуск команды через cli
```sh
$ ansible appserver -i ./inventory -m ping
$ ansible app -m command -a 'ruby -v'
$ ansible app -m command -a 'ruby -v; bundler -v'

$ ansible db -m command -a 'systemctl status mongod'
$ ansible db -m shell -a 'systemctl status mongod'
$ ansible db -m systemd -a name=mongod
$ ansible db -m service -a name=mongod
```

> Модуль command выполняет команды, не используя оболочку (sh, bash), поэтому в нем не работают перенаправления потоков и нет доступа к некоторым переменным окружения

#### ansible.cfg
```sh
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

#### Плейбуки
```sh
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit

# Запуск плейбука
$ ansible-playbook clone.yml
```
> При использовании команды

> ansible app -m command -a 'rm -rf ~/reddit' 

> Программа указывает о необходимости исползования специального модуля 'file', для соблюдения идемпотентности

#### Динамический inventory
Создал файл inventory.json, запуск
```sh
$ ansible all -m ping -i getinv.sh
```

>Для полноценной проверки динамического инвентори создал файл getvm.py. Данный скрипт подключается к GCP и выводит в JSON список IP адресов виртуальных машин.


********************************

## Homework-07

Импорт существующего ресурса в терраформ
```sh
$ terraform import google_compute_firewall.firewall_ssh default-allow-ssh
 ```
Добавить статический IP
```sh
resource "google_compute_address" "app_ip" { 
  name = "reddit-app-ip"
}
```
Ссылаемся на атрибуты другого ресурса
```sh
# Неявная зависимость
network_interface {
    network       = "default"
    access_config = {
      nat_ip = "$google_compute_address.app_ip.address}"
    }
  }

# явную зависимость можно задать через
depends_on
```
### Модули
Модули размещаем в папке ../modules
```sh
# Для подключения модуля выполнить
$ terraform get
```
Получаем output переменные из модуля
```sh
output "app_external_ip" {
  value = "${module.app.app_external_ip}"
}
```
Работа с реестром модулей
```sh
module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name = ["storage-bucket-test", "storage-bucket-test2"]
}

output storage-bucket_url {
  value = "${module.storage-bucket.url}"
}
```
Удаленный бекэнд (для коллективной работы terraform.tfstate храним в бакете)
```sh
terraform {
  backend "gcs" {
    bucket  = "boygruv-tf-state-stage"
    prefix  = "terraform/state"
  }
}
```

****************************************************************************

## Homework-06

Установка Terraform:
```
$ wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip 
$ unzip terraform_0.11.10_linux_amd64.zip
$ mv terraform /usr/local/bin/ 
$ terraform -v 
```
Определим провайдера в файл main.tf и скачаем бинарные файлы выбранного провайдера: 
```
$ terraform init
```
Тестирование плана
```
$ terraform plan
```
Применение плана
```
$ terraform apply
```
Просмотр terraform.tfstate
```
$ terraform show | grep assigned_nat_ip
$ terraform refresh
```
Output переменные. Описываем в outputs.tf
```
output "app_external_ip" {
  value = "${google_compute_instance.app.network_interface.0.access_config.0.assigned_nat_ip}"
}

## Просмотр output переменных
$ terraform output
$ terraform output app_external_ip 
```

Пересоздать ресурс при следующем изменении
```
$ terraform taint google_compute_instance.app
```
Input переменные. Определяем в файле variables.tf, тамже задаем значения по умолчанию
```
## Пример использования input переменных
provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}
...
  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
```

Удалить все ресурсы
```
$ terraform destroy
```

**ВАЖНО** если ресурс добавить через web-интерфейс GCP, то при накатке ресурса терраформ удалит
ресурс и приветет в соответствие описанное в конфиках терраформа

Pадание со *: при добавлении второго инстанта VM копированием кода в main.tf имеем следующие проблемы:
 - Дублирование кода
 - Ручное управление, необходимо руками задавать имя VM
 - При использовании большого количества VM становится не рациональным


****************************************************************************

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


