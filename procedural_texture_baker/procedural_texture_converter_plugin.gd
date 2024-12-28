extends EditorResourceConversionPlugin


func _handles(resource: Resource):

	return resource is Texture2D and resource is not PortableCompressedTexture2D


func _converts_to():

	return "PortableCompressedTexture2D"


func _convert(input: Resource):

	var output := PortableCompressedTexture2D.new()
	output.create_from_image(input.get_image(), PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	return output
