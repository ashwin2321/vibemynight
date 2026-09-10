package com.vibemynight.backend.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.net.URI;

@Configuration
public class DataSourceConfig {

    private static final Logger log = LoggerFactory.getLogger(DataSourceConfig.class);

    @Value("${DATABASE_URL:#{null}}")
    private String databaseUrl;

    @Value("${MYSQL_URL:${MYSQLURL:#{null}}}")
    private String mysqlUrl;

    @Value("${MYSQL_HOST:${MYSQLHOST:#{null}}}")
    private String mysqlHost;

    @Value("${MYSQL_PORT:${MYSQLPORT:#{null}}}")
    private String mysqlPort;

    @Value("${MYSQL_DATABASE:${MYSQLDATABASE:#{null}}}")
    private String mysqlDatabase;

    @Value("${MYSQL_USER:${MYSQLUSER:#{null}}}")
    private String mysqlUser;

    @Value("${MYSQL_PASSWORD:${MYSQLPASSWORD:#{null}}}")
    private String mysqlPassword;

    @Value("${spring.datasource.url:jdbc:mysql://localhost:3306/vibemynight?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true}")
    private String fallbackUrl;

    @Value("${spring.datasource.username:root}")
    private String fallbackUsername;

    @Value("${spring.datasource.password:root}")
    private String fallbackPassword;

    @Bean
    @Primary
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setDriverClassName("com.mysql.cj.jdbc.Driver");

        String rawUrl = mysqlUrl != null && !mysqlUrl.trim().isEmpty() ? mysqlUrl : databaseUrl;

        if (rawUrl != null && !rawUrl.trim().isEmpty() && (rawUrl.startsWith("mysql://") || rawUrl.startsWith("mysql2://"))) {
            try {
                URI uri = new URI(rawUrl.replace("mysql2://", "mysql://"));
                String host = uri.getHost();
                int port = uri.getPort() > 0 ? uri.getPort() : 3306;
                String path = uri.getPath() != null && uri.getPath().length() > 1 ? uri.getPath().substring(1) : "railway";
                
                String username = null;
                String password = null;
                if (uri.getUserInfo() != null) {
                    String[] userInfo = uri.getUserInfo().split(":", 2);
                    username = userInfo[0];
                    if (userInfo.length > 1) {
                        password = userInfo[1];
                    }
                }

                String jdbcUrl = String.format(
                        "jdbc:mysql://%s:%d/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&createDatabaseIfNotExist=true",
                        host, port, path
                );

                log.info("Connecting via parsed Cloud MySQL URI: {}:{}", host, port);
                config.setJdbcUrl(jdbcUrl);
                if (username != null) config.setUsername(username);
                if (password != null) config.setPassword(password);

            } catch (Exception e) {
                log.warn("Failed to parse Cloud MySQL URI, falling back to standard JDBC URL: {}", e.getMessage());
                config.setJdbcUrl(rawUrl.startsWith("jdbc:") ? rawUrl : "jdbc:" + rawUrl);
                if (mysqlUser != null) config.setUsername(mysqlUser);
                if (mysqlPassword != null) config.setPassword(mysqlPassword);
            }
        } else if (mysqlHost != null && !mysqlHost.trim().isEmpty()) {
            int port = 3306;
            if (mysqlPort != null) {
                try { port = Integer.parseInt(mysqlPort); } catch (NumberFormatException ignored) {}
            }
            String db = (mysqlDatabase != null && !mysqlDatabase.trim().isEmpty()) ? mysqlDatabase : "railway";
            String jdbcUrl = String.format(
                    "jdbc:mysql://%s:%d/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&createDatabaseIfNotExist=true",
                    mysqlHost, port, db
            );
            log.info("Connecting via Railway MySQL Host: {}:{}", mysqlHost, port);
            config.setJdbcUrl(jdbcUrl);
            config.setUsername(mysqlUser != null ? mysqlUser : "root");
            config.setPassword(mysqlPassword != null ? mysqlPassword : "");
        } else {
            String isCloud = System.getenv("PORT");
            if (isCloud != null && !isCloud.trim().isEmpty() && fallbackUrl.contains("localhost")) {
                log.info("No cloud MySQL host provided. Using resilient embedded in-memory database to prevent startup crash.");
                config.setDriverClassName("org.h2.Driver");
                config.setJdbcUrl("jdbc:h2:mem:vibemynight;MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE");
                config.setUsername("sa");
                config.setPassword("");
            } else {
                log.info("Connecting via standard configured DataSource URL: {}", fallbackUrl);
                config.setJdbcUrl(fallbackUrl);
                config.setUsername(fallbackUsername);
                config.setPassword(fallbackPassword);
            }
        }

        // Resilient connection pool settings for cloud environments
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);

        return new HikariDataSource(config);
    }
}
