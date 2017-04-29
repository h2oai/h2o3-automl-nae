NAME:=h2o3_automl_nae

image: Dockerfile
	docker build -t $(NAME) .

tag: image
	docker tag $(NAME) opsh2oai/$(NAME)

push : tag
	docker push opsh2oai/$(NAME) && docker push opsh2oai/$(NAME)
