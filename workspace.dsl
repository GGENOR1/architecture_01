workspace {
    name "Сайт конференций"
    description "Система управления конференциями"

    # включаем режим с иерархической системой идентификаторов
    !identifiers hierarchical

    !docs documentation
    !adrs decisions
    # Модель архитектуры
    model {

        # Настраиваем возможность создания вложенных груп
        properties { 
            structurizr.groupSeparator "/"
        }
        

        # Описание компонент модели
        user = person "Пользователь"
        conference_system = softwareSystem "Система конференций" {
            description "Сервер управления конференциями и докладами"

            user_service = container "User service" {
                description "Сервис управления пользователями"
            }

            conference_service = container "Conference service" {
                description "Сервис управления конференциями"
            }
            reports_service = container "Reports service" {
                description "Сервис управления докладами"
            }

            group "Слой данных" {
                user_database = container "User Database" {
                    description "База данных с данными пользователей"
                    technology "PostgreSQL 16"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кеш пользовательских данных"
                    technology "Redis 7.2"
                    tags "database"
                }

                Conference_database = container "Conference Database" {
                    description "База данных с данными о докладах и конференциях"
                    technology "MongoDB 7.0.6"
                    tags "database"
                }
            }

            user_service -> user_cache "Получение/обновление данных о пользователях" "TCP 6379"
            user_service -> user_database "Получение/обновление данных о пользователях" "TCP 5432"

            conference_service -> Conference_database "Получение/обновление данных о конференциях" "TCP 27018"
            conference_service -> user_service "Аутентификация пользователя" "REST HTTP 443"
            reports_service -> user_service "Аутентификация пользователя" "REST HTTP 443"
          
            reports_service -> Conference_database "Получение/обновление данных о докладах" "TCP 27018"
            user -> conference_system "Добавление докладов и участие в конференциях" "REST HTTP:8080" 
            user -> conference_service "Добавление конференций" "REST HTTP:8080"
            user -> reports_service "Добавление докладов " "REST HTTP:8080"
            user -> user_service "Регистрация нового пользователя" "REST HTTP:8080"
        
        }

        

        deploymentEnvironment "Production" {
            deploymentNode "User Server" {
                containerInstance conference_system.user_service
            }

            deploymentNode "Conference Server" {
                containerInstance conference_system.conference_service
            }
             deploymentNode "Reports Server" {
                containerInstance conference_system.reports_service
            }

            deploymentNode "databases" {
     
                deploymentNode "Database Server 1" {
                    containerInstance conference_system.user_database
                }

                deploymentNode "Database Server 2" {
                    containerInstance conference_system.Conference_database
                    instances 3
                }

                deploymentNode "Cache Server" {
                    containerInstance conference_system.user_cache
                }
            }
            
        }
    }

    views {
        themes default

        properties { 
            structurizr.tooltips true
        }


        !script groovy {
            workspace.views.createDefaultViews()
            workspace.views.views.findAll { it instanceof com.structurizr.view.ModelView }.each { it.enableAutomaticLayout() }
        }

        dynamic conference_system "UC01" "Добавление нового пользователя" {
            autoLayout
            user -> conference_system.user_service "Создание нового пользователя (POST /user)"
            conference_system.user_service -> conference_system.user_database "Сохранение данных о пользователе" 
        }

        dynamic conference_system "UC02" "Удаление пользователя" {
            autoLayout
            user -> conference_system.user_service "Удаление пользователя (DELETE /user)" 
            conference_system.user_service -> conference_system.user_database "Удаление данных о пользователе" 
        }

        dynamic conference_system "UC03" "Создание нового доклада" {
            autoLayout
            user -> conference_system.reports_service "Создание нового доклада (POST /reports)"
            conference_system.reports_service -> conference_system.user_service "Проверить аутентификацию пользователя (GET /user)"
            conference_system.reports_service -> conference_system.Conference_database "Сохранение доклада" 
        }

        dynamic conference_system "UC04" "Получение списка всех докладов" {
            autoLayout
            user -> conference_system.reports_service "Получение списка всех докладов (GET /reports)"
            conference_system.reports_service -> conference_system.user_service "Проверить аутентификацию пользователя (GET /user)"
            conference_system.reports_service -> conference_system.Conference_database "Получение списка всех докладов" 
        }

        dynamic conference_system "UC05" "Добавление доклада в конференцию" {
            autoLayout
            user -> conference_system.conference_service "Добавление доклада в конференцию (POST /сonference)"
            conference_system.conference_service -> conference_system.user_service "Проверить аутентификацию пользователя (GET /user)"
            conference_system.conference_service -> conference_system.Conference_database "Добавление доклада в конференцию" 
        }

            dynamic conference_system "UC06" "Получение списка докладов в конференции" {
            autoLayout
            user -> conference_system.conference_service "Получение списка докладов в конференции (GET /сonference)"
            conference_system.conference_service -> conference_system.user_service "Проверить аутентификацию пользователя (GET /user)"
            conference_system.conference_service -> conference_system.Conference_database "Добавление доклада в конференцию" 
        }


        styles {
            element "database" {
                shape cylinder
            }
        }
    }
}