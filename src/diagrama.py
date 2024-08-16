from diagrams import Cluster, Diagram
from diagrams.aws.compute import ECS
from diagrams.aws.database import RDS
from diagrams.aws.network import ELB, Route53
from diagrams.aws.integration import SQS, SNS
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch

# Gerando o diagrama com base no código modificado
with Diagram("Computer Parts Store", show=False, outformat="png", filename="computer_parts_store"):
    dns = Route53("DNS")
    lb = ELB("Load Balancer")

    with Cluster("Application Services"):
        web_app = ECS("Web Application")
        api = ECS("API")
        admin_panel = ECS("Admin Panel")

    with Cluster("Database Cluster"):
        db_primary = RDS("MainDB")
        db_primary - [RDS("MainDB Read-Replica")]

    s3_storage = S3("Product Images")

    with Cluster("E-commerce Functionality"):
        quote_svc = ECS("Quote Service")
        report_svc = ECS("Sales Report Service")
        customer_svc = ECS("Customer Service")
        product_svc = ECS("Product Service")
        delivery_svc = ECS("Delivery Service")

    with Cluster("Notifications and Queue"):
        sns_notifications = SNS("Order Notifications")
        sqs_queue = SQS("Order Queue")

    with Cluster("Logging and Monitoring"):
        cloudwatch_logs = Cloudwatch("CloudWatch Logs")
        cloudwatch_alarms = Cloudwatch("CloudWatch Alarms")

    dns >> lb >> web_app
    web_app >> api
    web_app >> admin_panel
    
    api >> quote_svc
    api >> report_svc
    api >> customer_svc
    api >> product_svc
    api >> delivery_svc
    
    quote_svc >> db_primary
    report_svc >> db_primary
    customer_svc >> db_primary
    product_svc >> db_primary
    delivery_svc >> sns_notifications
    delivery_svc >> sqs_queue
    
    product_svc >> s3_storage
    
    # Conectando os serviços ao CloudWatch para logs e monitoramento
    web_app >> cloudwatch_logs
    api >> cloudwatch_logs
    admin_panel >> cloudwatch_logs

    cloudwatch_logs >> cloudwatch_alarms
