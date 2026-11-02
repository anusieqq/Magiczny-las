using UnityEngine;

[ExecuteAlways]
public class GodRaysController : MonoBehaviour
{
    public Camera targetCamera;
    public Light directionalLight;
    public Material godRaysMaterial;

    [Header("P?ynno?? efektu")]
    [Range(0.1f, 5f)]
    public float smoothSpeed = 1.5f;

    [Header("Widoczno?? promieni")]
    [Range(0f, 1f)]
    public float minimumIntensity = 0.2f;

    private static readonly int LightScreenPos =
        Shader.PropertyToID("_LightScreenPos");

    private static readonly int RayIntensity =
        Shader.PropertyToID("_RayIntensity");

    private float currentIntensity;

    void LateUpdate()
    {
        if (targetCamera == null ||
            directionalLight == null ||
            godRaysMaterial == null)
            return;

        Vector3 lightDirection =
            -directionalLight.transform.forward;

        Vector3 lightPoint =
            targetCamera.transform.position + lightDirection * 1000f;

        Vector3 screenPosition =
            targetCamera.WorldToViewportPoint(lightPoint);

        // Pozycja ?wiat?a na ekranie
        float x = Mathf.Clamp(screenPosition.x, -1f, 2f);
        float y = Mathf.Clamp(screenPosition.y, -1f, 2f);

        // Obliczamy, czy ?wiat?o znajduje si? przed kamer?
        float frontFactor = screenPosition.z > 0f ? 1f : 0f;

        // P?ynna intensywno?? zale?na od wysoko?ci ?wiat?a
        float heightFactor = Mathf.InverseLerp(0.0f, 0.8f, y);

        heightFactor = Mathf.SmoothStep(0f, 1f, heightFactor);

        float targetIntensity =
            minimumIntensity +
            heightFactor * (1f - minimumIntensity);

        // Je?li ?wiat?o jest za kamer?, wygaszamy efekt stopniowo
        targetIntensity *= frontFactor;

        // Aktualizacja pozycji ?wiat?a
        godRaysMaterial.SetVector(
            LightScreenPos,
            new Vector4(x, y, 0f, 1f)
        );

        // P?ynne przej?cie w obie strony
        float speed = Mathf.Max(0.01f, smoothSpeed);

        currentIntensity = Mathf.Lerp(
            currentIntensity,
            targetIntensity,
            1f - Mathf.Exp(-speed * Time.deltaTime)
        );

        godRaysMaterial.SetFloat(
            RayIntensity,
            currentIntensity
        );
    }
}